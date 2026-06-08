pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
    }

    environment {
        AWS_REGION = 'us-east-1'
        TF_DIR     = 'terraform'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        ansiColor('xterm')
        timestamps()
    }

    stages {
        stage('Terraform Format Check') {
            steps {
                sh 'terraform -chdir=${TF_DIR} fmt -check -recursive'
            }
        }

        stage('Helm Lint') {
            steps {
                sh '''
                    helm lint helm/task-manager -f helm/task-manager/values-dev.yaml
                    helm lint helm/task-manager -f helm/task-manager/values-prod.yaml
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh 'terraform -chdir=${TF_DIR} init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
                    string(credentialsId: 'tf-db-password', variable: 'TF_VAR_db_password')
                ]) {
                    sh 'terraform -chdir=${TF_DIR} plan -var-file=terraform.tfvars -out=tfplan'
                }
            }
        }

        stage('Approval') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                input message: "Approve Terraform ${params.ACTION}?", ok: 'Proceed'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
                    string(credentialsId: 'tf-db-password', variable: 'TF_VAR_db_password')
                ]) {
                    sh 'terraform -chdir=${TF_DIR} apply tfplan'
                }
            }
        }

        stage('Install Cluster Add-ons') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh '''
                        aws eks update-kubeconfig --region ${AWS_REGION} --name task-manager-eks

                        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        LBC_ROLE_ARN=$(terraform -chdir=${TF_DIR} output -raw lbc_role_arn)
                        OIDC_PROVIDER_ARN=$(terraform -chdir=${TF_DIR} output -raw eks_oidc_provider_arn)
                        OIDC_ID=$(echo $OIDC_PROVIDER_ARN | cut -d'/' -f4)

                        # Update ExternalDNSRole trust policy with the new cluster OIDC ID
                        cat > /tmp/external-dns-trust.json << TRUSTEOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${AWS_REGION}.amazonaws.com/id/${OIDC_ID}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "oidc.eks.${AWS_REGION}.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:kube-system:external-dns",
        "oidc.eks.${AWS_REGION}.amazonaws.com/id/${OIDC_ID}:aud": "sts.amazonaws.com"
      }
    }
  }]
}
TRUSTEOF
                        aws iam update-assume-role-policy \
                            --role-name ExternalDNSRole \
                            --policy-document file:///tmp/external-dns-trust.json

                        helm repo add eks https://aws.github.io/eks-charts
                        helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
                        helm repo update

                        helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
                            -n kube-system \
                            --set clusterName=task-manager-eks \
                            --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=${LBC_ROLE_ARN}" \
                            --wait --timeout 5m

                        helm upgrade --install external-dns external-dns/external-dns \
                            -n kube-system \
                            --set provider=aws \
                            --set aws.region=${AWS_REGION} \
                            --set txtOwnerId=task-manager-eks \
                            --set policy=upsert-only \
                            --set serviceAccount.name=external-dns \
                            --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=arn:aws:iam::${ACCOUNT_ID}:role/ExternalDNSRole" \
                            --wait --timeout 3m
                    '''
                }
            }
        }

        stage('Create K8s Secrets') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
                    string(credentialsId: 'tf-db-password', variable: 'TF_VAR_db_password')
                ]) {
                    sh '''
                        aws eks update-kubeconfig --region ${AWS_REGION} --name task-manager-eks
                        RDS_HOST=$(terraform -chdir=${TF_DIR} output -raw rds_endpoint)
                        for NS in dev prod; do
                            if [ "$NS" = "prod" ]; then
                                DB_NAME="taskmanager"
                            else
                                DB_NAME="taskmanager_dev"
                            fi
                            DB_URL="postgresql://taskuser:${TF_VAR_db_password}@${RDS_HOST}:5432/${DB_NAME}"
                            kubectl create namespace ${NS} --dry-run=client -o yaml | kubectl apply -f -
                            kubectl create secret generic db-secret -n ${NS} \
                                --from-literal=DATABASE_URL="${DB_URL}" \
                                --dry-run=client -o yaml | kubectl apply -f -
                        done
                    '''
                }
            }
        }

        stage('Pre-Destroy Cleanup') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-credentials'
                ]]) {
                    sh '''
                        aws eks update-kubeconfig --region ${AWS_REGION} --name task-manager-eks

                        # Uninstall app helm releases so the ALB controller deletes the ALB
                        for NS in dev prod; do
                            for RELEASE in frontend backend; do
                                helm uninstall ${RELEASE} -n ${NS} 2>/dev/null || true
                            done
                        done

                        # Wait for ALBs to be fully deleted before Terraform touches the VPC
                        echo "Waiting for load balancers to be deleted..."
                        for i in $(seq 1 36); do
                            COUNT=$(aws elbv2 describe-load-balancers --region ${AWS_REGION} \
                                --query "length(LoadBalancers[?contains(LoadBalancerName,'k8s')])" \
                                --output text 2>/dev/null || echo "0")
                            if [ "${COUNT}" = "0" ]; then
                                echo "All load balancers deleted"
                                break
                            fi
                            echo "Waiting... ${COUNT} LB(s) still active"
                            sleep 10
                        done
                    '''
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials'],
                    string(credentialsId: 'tf-db-password', variable: 'TF_VAR_db_password')
                ]) {
                    sh 'terraform -chdir=${TF_DIR} destroy -var-file=terraform.tfvars -auto-approve'
                }
            }
        }
    }
}
