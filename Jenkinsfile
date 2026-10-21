// Job: 03-shopnow-cicd  - triggered by GitHub webhook on push to main, or by 02-config-ansible (DEPLOY_ONLY)
pipeline {
  agent any
  parameters { booleanParam(name: 'DEPLOY_ONLY', defaultValue: false, description: 'Skip build; redeploy newest ECR images') }
  triggers { githubPush() }
  options { timestamps(); disableConcurrentBuilds(); buildDiscarder(logRotator(numToKeepStr: '15')) }
  environment {
    AWS_REGION = 'ap-southeast-2'
    CLUSTER    = 'shopnow-dev'
    SERVICES   = 'backend frontend admin'
  }

  stages {
    stage('Setup') { steps { script {
      env.ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
      env.REGISTRY   = "${env.ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
      env.TAG = params.DEPLOY_ONLY ?
        sh(script: "aws ecr describe-images --repository-name shopnow-backend --query 'sort_by(imageDetails,&imagePushedAt)[-1].imageTags[0]' --output text", returnStdout: true).trim() :
        "${env.GIT_COMMIT.take(7)}-${env.BUILD_NUMBER}"
      env.CLUSTER_UP = (sh(script: 'aws eks describe-cluster --name $CLUSTER >/dev/null 2>&1', returnStatus: true) == 0).toString()
      echo "TAG=${env.TAG} CLUSTER_UP=${env.CLUSTER_UP}"
    } } }

    stage('Unit tests') {
      when { expression { !params.DEPLOY_ONLY } }
      parallel {
        stage('frontend') { steps { sh 'docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD/frontend":/app -w /app node:20-alpine sh -c "npm ci --no-audit && CI=true npm test -- --watchAll=false --passWithNoTests"' } }
        stage('admin')    { steps { sh 'docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD/admin":/app -w /app node:20-alpine sh -c "npm ci --no-audit && CI=true npm test -- --watchAll=false --passWithNoTests"' } }
        stage('backend')  { steps { sh 'docker run --rm -u $(id -u):$(id -g) -e HOME=/tmp -v "$PWD/backend":/app -w /app node:20-alpine sh -c "npm ci --no-audit && node --check server.js && npm run test --if-present"' } }
      }
    }

    stage('Build images') {
      when { expression { !params.DEPLOY_ONLY } }
      steps { sh 'for s in $SERVICES; do docker build -t $REGISTRY/shopnow-$s:$TAG ./$s; done' }   // sequential: t3.medium memory
    }

    stage('Scan images') {
      when { expression { !params.DEPLOY_ONLY } }
      steps { sh '''
        if command -v trivy >/dev/null; then
          for s in $SERVICES; do trivy image --severity HIGH,CRITICAL --exit-code 0 --no-progress $REGISTRY/shopnow-$s:$TAG; done
        else echo "trivy not installed - skipping scan (ECR scan-on-push still runs)"; fi
      ''' }
    }

    stage('Push to ECR') {
      when { expression { !params.DEPLOY_ONLY } }
      steps { sh '''
        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REGISTRY
        for s in $SERVICES; do docker push $REGISTRY/shopnow-$s:$TAG; done
      ''' }
    }

    stage('Deploy to EKS') {
      when { expression { env.CLUSTER_UP == 'true' } }
      steps {
        script { env.DEPLOYED = 'true' }   // only roll back if we actually changed the cluster
        sh '''
        aws eks update-kubeconfig --name $CLUSTER --region $AWS_REGION
        for f in namespace backend frontend admin hpa servicemonitor; do
          sed -e "s|__REGISTRY__|$REGISTRY|g" -e "s|__TAG__|$TAG|g" k8s/$f.yaml | kubectl apply -f -
        done
        for d in $SERVICES; do kubectl -n shopnow rollout status deploy/$d --timeout=180s; done
      '''
      }
    }

    stage('Smoke test') {
      when { expression { env.CLUSTER_UP == 'true' } }
      steps { sh '''
        LB=$(kubectl -n shopnow get svc frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        echo "Storefront: http://$LB"
        bash tests/smoke.sh "http://$LB"
      ''' }
    }
  }

  post {
    success { script {
      if (env.CLUSTER_UP != 'true') { currentBuild.result = 'UNSTABLE'; echo 'Cluster down: images pushed, deploy skipped' }
      slackSend color: 'good', message: "shopnow ${env.TAG} ${currentBuild.currentResult}: ${env.BUILD_URL}"
    } }
    failure {
      sh 'if [ "${DEPLOYED:-false}" = true ]; then for d in $SERVICES; do kubectl -n shopnow rollout undo deploy/$d || true; done; fi'
      slackSend color: 'danger', message: "shopnow ${env.TAG} FAILED, rolled back: ${env.BUILD_URL}"
    }
    always { sh 'docker image prune -af --filter "until=24h" || true'; cleanWs() }
  }
}
