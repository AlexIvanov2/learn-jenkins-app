pipeline {
  agent any

  environment {
    NETLIFY_SITE_ID    = '82900fd4-6a59-4989-9a8a-85a4c975c113'
    NETLIFY_AUTH_TOKEN = credentials('netlify-token')
  }

  stages {

    stage('Build') {
      agent { docker { image 'node:18-alpine'; reuseNode true } }
      steps {
        sh '''
          set -eux
          node --version
          npm --version
          npm ci
          npm run build
          ls -la
        '''
      }
    }

    stage('Tests') {
      parallel {
        stage('Unit tests') {
          agent { docker { image 'node:18-alpine'; reuseNode true } }
          steps {
            sh '''
              set -eux
              npm ci
              npm test
            '''
          }
          post { always { junit 'jest-results/junit.xml' } }
        }

        stage('E2E') {
          agent { docker { image 'mcr.microsoft.com/playwright:v1.39.0-jammy'; reuseNode true } }
          steps {
            sh '''
              set -eux
              npm ci
              npm install --no-save serve
              node_modules/.bin/serve -s build &
              sleep 10
              npx playwright test --reporter=html
            '''
          }
          post {
            always {
              publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false,
                reportDir: 'playwright-report', reportFiles: 'index.html',
                reportName: 'Playwright local Report', reportTitles: '', useWrapperFileDirectly: true])
            }
          }
        }
      }
    }

    stage('Deploy Staging') {
      agent { docker { image 'node:18-alpine'; reuseNode true } }
      steps {
        sh '''
          set -eux
          test -d build

          npm ci
          npx netlify-cli --version

          echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
          npx netlify-cli deploy --dir=build --site "$NETLIFY_SITE_ID" --no-build
          echo "Staging deployment completed."
        '''
      }
    }

    stage('Approve Production') {
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Staging deployed. Approve deployment to PRODUCTION?',
                ok: 'Deploy to Production'
        }
      }
    }

    stage('Deploy Production') {
      agent { docker { image 'node:18-alpine'; reuseNode true } }
      steps {
        sh '''
          set -eux
          test -d build

          npm ci
          npx netlify-cli --version

          echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"
          npx netlify-cli deploy --prod --dir=build --site "$NETLIFY_SITE_ID" --no-build
          echo "Production deployment completed."
        '''
      }
    }

    stage('Prod E2E') {
      agent { docker { image 'mcr.microsoft.com/playwright:v1.39.0-jammy'; reuseNode true } }
      environment {
        CI_ENVIRONMENT_URL = "https://helpful-squirrel-217942.netlify.app"
      }
      steps {
        sh '''
          set -eux
          npm ci
          npx playwright test --reporter=html
        '''
      }
      post {
        always {
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false,
            reportDir: 'playwright-report', reportFiles: 'index.html',
            reportName: 'Playwright E2E Report', reportTitles: '', useWrapperFileDirectly: true])
        }
      }
    }

  }
}
