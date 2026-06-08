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
