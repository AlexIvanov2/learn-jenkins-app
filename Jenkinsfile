pipeline {
    agent any

    environment {
        // This is your Netlify *Site ID* (not "project")
        NETLIFY_SITE_ID    = '82900fd4-6a59-4989-9a8a-85a4c975c113'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
    }

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
                    ls -la
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
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            set -eux
                            npm ci
                            npm test
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }

                stage('E2E') {
                    agent {
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.39.0-jammy'
                            reuseNode true
                        }
                    }
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
                                alwaysLinkToLastBuild: false,
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Playwright HTML Report',
                                reportTitles: '',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    set -eux
                    npm ci
                    npx netlify-cli --version

                    echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"

                    # Explicitly target the Netlify site (no need for `netlify link` / .netlify/state.json)
                    npx netlify status --site "$NETLIFY_SITE_ID" --auth "$NETLIFY_AUTH_TOKEN"
                    npx netlify deploy --dir=build --prod --site "$NETLIFY_SITE_ID" --auth "$NETLIFY_AUTH_TOKEN"
                '''
            }
        }
    }
}
