pipeline {
  agent any

      // environment {
      //   AWS_ACCESS_KEY_ID = credentials('jenkins_aws_user').AWS_ACCESS_KEY_ID
      //   AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_user').AWS_SECRET_ACCESS_KEY
      // }

  stages {

    stage('Plan') {
      steps {
        withAWS(credentials: 'aws-credentials') {
          sh 'terraform init'
          sh 'terraform plan'
        }
      }
    }

    stage('Apply') {
      steps {
        input "Deploy infrastructurstepse? Type 'deploy' to proceed."
        withAWS(credentials: 'jenkins_aws_user') { 
          sh 'terraform apply -auto-approve'
        }
      }
    }

    stage('Destroy') {
      steps {
        input 'Are you sure you want to destroy infrastructure? Type "destroy" to proceed.'
        withAWS(credentials: 'jenkins_aws_user') {
          sh 'terraform destroy'
        }
      }
    }
  }
}
