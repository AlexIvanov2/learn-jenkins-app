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

          ls -la
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
          set -eux
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
          set -eux

          # Avoid reusing Alpine-built node_modules in Ubuntu-based Playwright image
          rm -rf node_modules
          npm ci

          # Start static server and ensure it is stopped at the end
          npx --yes serve -s build -l 4173 &
          SERVER_PID=$!
          trap "kill $SERVER_PID || true" EXIT

          sleep 2

          # Sanity checks
          npx playwright --version
          npx playwright install --check

          # Run E2E
          npx playwright test --reporter=html
        '''
      }
      post {
        always {
          // Archive Playwright HTML report (path can be playwright-report or test-results depending on config)
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
