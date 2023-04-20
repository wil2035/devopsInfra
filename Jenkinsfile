pipeline {
  agent any
  triggers {
    githubPush()
  }
  environment {
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
  }

  stages {
    stage('Initialize') {
      steps {
        sh 'terraform init'
      }
    }

    stage('Plan') {
      steps {
        script {
          def plan_output = sh (
            script: 'terraform plan -input=false -out=tfplan',
            returnStdout: true
          )
          echo "Plan output:\n${plan_output}"
          writeFile file: 'terraform-plan.json', text: plan_output
        }
      }
    }

    stage('Apply') {
      steps {
        input message: 'Do you want to apply the changes?', ok: 'Yes', parameters: [
          booleanParam(defaultValue: false, description: 'Destroy all resources?', name: 'destroy')
        ]
        script {
          def destroy = params.destroy ? '-destroy' : ''
          sh "terraform apply -input=false ${destroy} -auto-approve tfplan"
        }
      }
    }

    stage('Destroy') {
      steps {
        input message: 'Do you want to destroy all resources?', ok: 'Yes', parameters: [
          booleanParam(defaultValue: false, description: 'Destroy all resources?', name: 'destroy')
        ]
        when {
          expression { params.destroy }
        }
        steps {
          sh 'terraform destroy -input=false -auto-approve'
        }
      }
    }
  }
}
