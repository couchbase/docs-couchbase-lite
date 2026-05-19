pipeline {
    agent none
    options {
        timeout(time: 10, unit: 'MINUTES')
    }
    stages {
        stage("Validate Build") {
            parallel {
                stage("Validate iOS") {
                    agent { label 'mobile-builder-ios-pull-request' }
                    steps {
                        sh 'jenkins/ios.sh 3.3.3 1.0.0'
                    }
                }
                stage("Validate Android") {
                    agent { label 'cbl-android' }
                    steps {
                        sh 'jenkins/android_build.sh 3.3.3 1.0.0'
                    }
                }
            }
        }
    }
}
