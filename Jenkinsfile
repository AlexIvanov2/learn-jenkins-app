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
          set -euxo pipefail
          node --version
          npm --version
          npm ci
          npm run build
          ls -la build | head -n 50
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
          set -euxo pipefail
          test -f build/index.html
          npm test
        '''
      }
    }

    stage('E2E') {
      agent {
        docker {
          image 'mcr.microsoft.com/playwright:v1.57.0-noble'
          reuseNode true
          args '--ipc=host'
        }
      }
      steps {
        sh '''
          set -euxo pipefail

          # IMPORTANT: install deps in this image (Ubuntu), not reuse Alpine node_modules
          rm -rf node_modules
          npm ci

          # Start static server and ensure it gets killed
          npx --yes serve -s build -l 4173 &
          SERVER_PID=$!
          trap "kill $SERVER_PID || true" EXIT

          sleep 2
          npx playwright --version
          npx playwright install --check
          npx playwright test --reporter=html
        '''
      }
    }
  }

  post {
    always {
      junit 'jest-results/junit.xml'
      // Optional: archive the Playwright HTML report if you want
      // archiveArtifacts artifacts: 'playwright-report/**', allowEmptyArchive: true
    }
  }
}
