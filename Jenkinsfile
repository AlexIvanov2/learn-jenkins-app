pipeline {
  agent any

  environment {
    NETLIFY_SITE_ID    = '82900fd4-6a59-4989-9a8a-85a4c975c113'
    NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    REACT_APP_VERSION  = "1.0.${BUILD_ID}"
  }

  stages {

    stage('Docker') {
      steps {
        sh '''
          set -eux
          docker build -t alex-docker .
        '''
      }
    }

    stage('Build') {
      agent { docker { image 'node:18-alpine'; reuseNode true } }
      steps {
        sh '''
          set -eux
          node --version
          npm --version

          # Install deps ONCE
          npm ci

          # Build ONCE
          npm run build

          test -d build
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
              # reuse node_modules from Build (no npm ci here)
              npm test
            '''
          }
          post { always { junit 'jest-results/junit.xml' } }
        }

        stage('Local E2E') {
          agent { docker { image 'alex-docker'; reuseNode true } }
          steps {
            sh '''
              set -eux
              test -d build

              # no npm ci here - reuse node_modules from Build
              npx --yes serve -s build &
              sleep 10

              npx playwright test --reporter=html
            '''
          }
          post {
            always {
              publishHTML([allowMissing: false,
                alwaysLinkToLastBuild: false,
                keepAll: false,
                reportDir: 'playwright-report',
                reportFiles: 'index.html',
                reportName: 'Local E2E',
                reportTitles: '',
                useWrapperFileDirectly: true
              ])
            }
          }
        }
      }
    }

    stage('Deploy + Staging E2E') {
      agent { docker { image 'alex-docker'; reuseNode true } }
      steps {
        sh '''
          set -eux
          test -d build

          node --version
          netlify --version
          jq --version

          echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"
          netlify status || true

          netlify deploy --dir=build --site $NETLIFY_SITE_ID --json | tee deploy-output.json

          STAGING_URL="$(jq -r '.deploy_url // .url // empty' deploy-output.json)"
          echo "Staging URL: $STAGING_URL"
          test -n "$STAGING_URL"

          CI_ENVIRONMENT_URL="$STAGING_URL" npx playwright test --reporter=html
        '''
      }
      post {
        always {
          publishHTML([allowMissing: false,
            alwaysLinkToLastBuild: false,
            keepAll: false,
            reportDir: 'playwright-report',
            reportFiles: 'index.html',
            reportName: 'Staging E2E',
            reportTitles: '',
            useWrapperFileDirectly: true
          ])
        }
      }
    }

    stage('Approve Production') {
      steps {
        timeout(time: 15, unit: 'MINUTES') {
          input message: 'Staging validated. Deploy to PRODUCTION?',
                ok: 'Deploy'
        }
      }
    }

    stage('Deploy + Prod E2E') {
      agent { docker { image 'alex-docker'; reuseNode true } }
      steps {
        sh '''
          set -eux
          test -d build

          node --version
          netlify --version
          jq --version

          echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"
          netlify status || true

          netlify deploy --prod --dir=build --site "$NETLIFY_SITE_ID" --no-build --json | tee deploy-output.json

          PROD_URL="$(jq -r '.deploy_url // .url // empty' deploy-output.json)"
          echo "Production URL: $PROD_URL"
          test -n "$PROD_URL"

          CI_ENVIRONMENT_URL="$PROD_URL" npx playwright test --reporter=html
        '''
      }
      post {
        always {
          publishHTML([allowMissing: false,
            alwaysLinkToLastBuild: false,
            keepAll: false,
            reportDir: 'playwright-report',
            reportFiles: 'index.html',
            reportName: 'Prod E2E',
            reportTitles: '',
            useWrapperFileDirectly: true
          ])
        }
      }
    }
  }
}