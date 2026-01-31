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

        stage('Local E2E') {
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
              publishHTML([
                allowMissing: false,
                reportDir: 'playwright-report',
                reportFiles: 'index.html',
                reportName: 'Local E2E'
              ])
            }
          }
        }
      }
    }

    stage('Deploy + Staging E2E') {
      agent { docker { image 'mcr.microsoft.com/playwright:v1.39.0-jammy'; reuseNode true } }

      steps {
        sh '''
          set -eux
          test -d build

          # Tools
          apk add --no-cache jq
          npm ci
          npx netlify-cli --version

          echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"

          # Deploy + capture output
          npx netlify-cli deploy --dir=build --site "$NETLIFY_SITE_ID" --no-build --json \
            | tee deploy-output.json

          # Extract deploy URL
          STAGING_URL="$(jq -r '.deploy_url // .url // empty' deploy-output.json)"
          echo "Staging URL: $STAGING_URL"
          test -n "$STAGING_URL"

          # Run E2E against staging
          CI_ENVIRONMENT_URL="$STAGING_URL" npx playwright test --reporter=html
        '''
      }

      post {
        always {
          publishHTML([
            allowMissing: false,
            reportDir: 'playwright-report',
            reportFiles: 'index.html',
            reportName: 'Staging E2E'
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
      agent { docker { image 'mcr.microsoft.com/playwright:v1.39.0-jammy'; reuseNode true } }

      steps {
        sh '''
          set -eux
          test -d build

          npm ci
          npx netlify-cli --version

          echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"

          npx netlify-cli deploy --prod --dir=build --site "$NETLIFY_SITE_ID" --no-build --json \
            | tee deploy-output.json

          PROD_URL="$(jq -r '.deploy_url // .url // empty' deploy-output.json)"
          echo "Production URL: $PROD_URL"
          test -n "$PROD_URL"

          CI_ENVIRONMENT_URL="$PROD_URL" npx playwright test --reporter=html
        '''
      }

      post {
        always {
          publishHTML([
            allowMissing: false,
            reportDir: 'playwright-report',
            reportFiles: 'index.html',
            reportName: 'Prod E2E'
          ])
        }
      }
    }
  }
}
