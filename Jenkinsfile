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
          // Match Docker image to your repo's Playwright version
          image 'mcr.microsoft.com/playwright:v1.39.0-noble'
          reuseNode true
          args '--ipc=host'
        }
      }
      steps {
        sh '''
          set -eux

          # Avoid reusing Alpine node_modules in Ubuntu-based image
          rm -rf node_modules
          npm ci

          npx --yes serve -s build -l 4173 &
          SERVER_PID=$!
          trap "kill $SERVER_PID || true" EXIT

          sleep 2

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
