pipeline {
  agent any

  stages {
    stage('Build') {
      agent {
        docker {
          image 'node:18-alpine'
          reuseNode true
        }
      }
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

    stage('Test') {
      agent {
        docker {
          image 'node:18-alpine'
          reuseNode true
        }
      }
      steps {
        sh '''
          set -eux
          test -f build/index.html
          npm test
        '''
      }
    }

    stage('E2E') {
      agent {
        docker {
          image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
          reuseNode true
          args '--ipc=host'
        }
      }
      steps {
        sh '''
          set -eux

          # Don't reuse Alpine node_modules in Ubuntu-based image
          rm -rf node_modules
          npm ci

          # Start app
          npx --yes serve -s build -l 4173 &
          SERVER_PID=$!
          trap "kill $SERVER_PID || true" EXIT

          # Wait for server
          npx --yes wait-on http://127.0.0.1:4173

          # Run E2E (point Playwright to the right port)
          PLAYWRIGHT_BASE_URL=http://127.0.0.1:4173 npx playwright test --reporter=html
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'playwright-report/**', allowEmptyArchive: true
        }
      }
    }
  }

  post {
    always {
      junit 'jest-results/junit.xml'
    }
  }
}
