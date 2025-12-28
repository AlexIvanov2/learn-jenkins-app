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

          # Clean deps for Ubuntu-based image
          rm -rf node_modules
          npm ci

          # Start app on port Playwright expects
          npx --yes serve -s build -l 3000 &
          SERVER_PID=$!
          trap "kill $SERVER_PID || true" EXIT

          # Wait until server is ready (Node 18 compatible)
          npx --yes wait-on@6.0.1 http://127.0.0.1:3000

          # Run E2E tests
          npx playwright test --reporter=html
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
