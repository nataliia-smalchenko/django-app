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
    - name: git-cli
      image: alpine/git:latest
      imagePullPolicy: Always
      command:
      - sleep
      args:
      - 99d
"""
        }
    }
    environment {
        ECR_REGISTRY = "658301803468.dkr.ecr.eu-central-1.amazonaws.com"
        IMAGE_NAME = "lesson-5-ecr"
        NEW_IMAGE_TAG = "${env.BUILD_ID}"
        HELM_REPO_URL = "https://github.com/nataliia-smalchenko/microservice-project.git"
        HELM_REPO_BRANCH = "lesson-8-9"
        HELM_CHART_PATH = "lesson-7/charts/django-app/values.yaml"
        GITHUB_CREDENTIALS_ID = "github-token"
    }
    stages {
        stage('Build & Push Docker Image') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \\
                        --context `pwd` \\
                        --dockerfile `pwd`/Dockerfile \\
                        --destination=$ECR_REGISTRY/$IMAGE_NAME:$NEW_IMAGE_TAG \\
                        --cache=true \\
                        --insecure \\
                        --skip-tls-verify
                    '''
                }
            }
        }
        
        stage('Update Helm Chart & Push to Git') {
            steps {
                container('git-cli') {
                    withCredentials([usernamePassword(credentialsId: "${GITHUB_CREDENTIALS_ID}", usernameVariable: 'GITHUB_USER', passwordVariable: 'GITHUB_TOKEN')]) {
                        script {
                            sh """
                                # Очищуємо робочу директорію
                                rm -rf helm-repo
                                
                                # Клонуємо Helm репозиторій з аутентифікацією
                                git clone --branch ${HELM_REPO_BRANCH} https://\${GITHUB_TOKEN}@github.com/nataliia-smalchenko/microservice-project.git helm-repo
                                
                                cd helm-repo
                                
                                # Встановлюємо yq
                                apk add --no-cache yq
                                
                                # Оновлюємо поле image.tag у values.yaml
                                yq eval '.image.tag = "${NEW_IMAGE_TAG}"' -i "${HELM_CHART_PATH}"
                                
                                # Оновлюємо також репозиторій образу
                                yq eval '.image.repository = "${ECR_REGISTRY}/${IMAGE_NAME}"' -i "${HELM_CHART_PATH}"
                                
                                # Налаштовуємо git
                                git config user.email "natalismalcenko@gmail.com"
                                git config user.name "nataliia-smalchenko"
                                
                                # Додаємо зміни та комітимо
                                git add "${HELM_CHART_PATH}"
                                git commit -m "feat(deploy): Update image tag to ${NEW_IMAGE_TAG} for ${IMAGE_NAME} [ci skip]"
                                
                                # Пушимо зміни до main branch (як вимагається)
                                git push origin HEAD:${HELM_REPO_BRANCH}
                            """
                        }
                    }
                }
            }
        }
    }
}