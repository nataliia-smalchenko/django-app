pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command:
        - sleep
      args:
        - 99d
"""
    }
  }

  environment {
    ECR_REGISTRY = "658301803468.dkr.ecr.eu-central-1.amazonaws.com/"
    IMAGE_NAME   = "lesson-5-ecr"
    NEW_IMAGE_TAG    = "${env.BUILD_ID}"

    HELM_REPO_URL    = "https://github.com/nataliia-smalchenko/microservice-project.git"
    HELM_REPO_BRANCH = "lesson-8-9"
    HELM_CHART_PATH  = "/lesson-7/charts/django-app/values.yaml"
    GITHUB_CREDENTIALS_ID = "github-token"
  }

  stages {
    stage('Clean Workspace') {
      steps {
        cleanWs() // Очищуємо робочу директорію перед початком
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        script {
            // If Dockerfile is in a subdirectory like 'app/Dockerfile'
            if (fileExists('\$(pwd)/Dockerfile')) { 
                echo "Dockerfile found. Building and pushing image."
                container('kaniko') {
                sh """
                    /kaniko/executor \\
                    --context=\$(pwd) \\
                    --dockerfile=\$(pwd)/Dockerfile \\ 
                    --destination=${ECR_REGISTRY}/${IMAGE_NAME}:${NEW_IMAGE_TAG} \\
                    --cache=true \\
                    --cache-repo=${ECR_REGISTRY}/kaniko-cache \\
                    --skip-tls-verify=true
                """
                }
            } else {
                error "Dockerfile not found at app/Dockerfile. Cannot build Docker image."
            }
        }
      }
    }

    stage('Update Helm Chart & Push to Git') {
      steps {
        container('git-cli') { 
          script {
            // Клонуємо репозиторій з Helm-чартом
            // `credentials()` використовує GitHub PAT з Jenkins Credentials
            git branch: "${HELM_REPO_BRANCH}",
                credentialsId: "${GITHUB_CREDENTIALS_ID}",
                url: "${HELM_REPO_URL}"
            
            // Переходимо до директорії Helm-чарту
            dir("${env.WORKSPACE}") { // Працюємо в корені клонованого репозиторію
              // Оновлюємо тег образу в values.yaml
              // Використовуємо 'yq' для безпечного оновлення YAML, або 'sed'
              // Приклад для `image.tag`:
              // image:
              //   repository: some-repo/image
              //   tag: old-tag
              sh """
                # Встановлюємо yq, якщо він не встановлений в образі alpine/git
                apk add --no-cache yq

                # Оновлюємо поле image.tag у values.yaml
                yq eval '.image.tag = "${NEW_IMAGE_TAG}"' -i "${HELM_CHART_PATH}"

                # Оновлюємо також репозиторій образу
                yq eval '.image.repository = "${ECR_REGISTRY}/${IMAGE_NAME}"' -i "${HELM_CHART_PATH}"

                git config user.email "natalismalcenko@gmail.com"
                git config user.name "nataliia-smalchenko"
                git add "${HELM_CHART_PATH}"
                git commit -m "feat(deploy): Update image tag to ${NEW_IMAGE_TAG} for ${IMAGE_NAME} [ci skip]"
                # [ci skip] - це поширена практика, щоб уникнути нескінченного циклу CI/CD
                
                # Пушимо зміни до GitHub
                git push origin ${HELM_REPO_BRANCH}
              """
            }
          }
        }
      }
    }
  }
}
