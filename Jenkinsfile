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
