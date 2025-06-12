pipeline {
    agent any
    
    parameters {
        string(name: 'KUBE_VERSION', defaultValue: 'v1.32.2', description: 'Kubernetes version to build')
        string(name: 'ETCD_VERSION', defaultValue: 'v3.5.9', description: 'etcd version to build')
        string(name: 'FLANNEL_VERSION', defaultValue: 'v0.26.4', description: 'Flannel version to build')
        string(name: 'CALICO_VERSION', defaultValue: 'v3.28.0', description: 'Calico version to build')
        choice(name: 'PACKAGE_TYPE', choices: ['deb', 'rpm'], description: 'Package type to build')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Components') {
            parallel {
                stage('Build kube-proxy') {
                    steps {
                        sh '''
                            KUBE_VERSION=${params.KUBE_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-kube-proxy
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'kube-proxy-packages'
                    }
                }
                
                stage('Build kubelet') {
                    steps {
                        sh '''
                            KUBE_VERSION=${params.KUBE_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-kubelet
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'kubelet-packages'
                    }
                }
                
                stage('Build etcd') {
                    steps {
                        sh '''
                            ETCD_VERSION=${params.ETCD_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-etcd
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'etcd-packages'
                    }
                }
                
                stage('Build kube-scheduler') {
                    steps {
                        sh '''
                            KUBE_VERSION=${params.KUBE_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-kube-scheduler
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'kube-scheduler-packages'
                    }
                }
                
                stage('Build kube-controller-manager') {
                    steps {
                        sh '''
                            KUBE_VERSION=${params.KUBE_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-kube-controller-manager
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'kube-controller-manager-packages'
                    }
                }
                
                stage('Build kube-apiserver') {
                    steps {
                        sh '''
                            KUBE_VERSION=${params.KUBE_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-kube-apiserver
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'kube-apiserver-packages'
                    }
                }
                
                stage('Build kubectl') {
                    steps {
                        sh '''
                            KUBE_VERSION=${params.KUBE_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-kubectl
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'kubectl-packages'
                    }
                }
                
                stage('Build flannel') {
                    steps {
                        sh '''
                            FLANNEL_VERSION=${params.FLANNEL_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-flannel
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'flannel-packages'
                    }
                }
                
                stage('Build calico') {
                    steps {
                        sh '''
                            CALICO_VERSION=${params.CALICO_VERSION} \\
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-calico
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'calico-packages'
                    }
                }
                
                stage('Build certificates') {
                    steps {
                        sh '''
                            PACKAGE_TYPE=${params.PACKAGE_TYPE} \\
                            DOCKER_COMPOSE="docker compose" \\
                            make build-certificates
                        '''
                        stash includes: 'output/*.deb,output/*.rpm', name: 'certificates-packages'
                    }
                }
            }
        }
        
        stage('Collect Artifacts') {
            steps {
                sh 'mkdir -p release-artifacts'
                
                unstash 'kube-proxy-packages'
                unstash 'kubelet-packages'
                unstash 'etcd-packages'
                unstash 'kube-scheduler-packages'
                unstash 'kube-controller-manager-packages'
                unstash 'kube-apiserver-packages'
                unstash 'kubectl-packages'
                unstash 'flannel-packages'
                unstash 'calico-packages'
                unstash 'certificates-packages'
                
                sh 'find output -type f \\( -name "*.deb" -o -name "*.rpm" \\) | xargs -I{} cp {} release-artifacts/'
                
                archiveArtifacts artifacts: 'release-artifacts/*', fingerprint: true
            }
        }
        
        stage('Create Package Repository') {
            steps {
                sh '''
                    mkdir -p debian/main rpm
                    
                    # Copy DEB packages to debian repo structure
                    cp release-artifacts/*.deb debian/main/ || true
                    
                    # Copy RPM packages to rpm repo structure
                    cp release-artifacts/*.rpm rpm/ || true
                    
                    if [ "${params.PACKAGE_TYPE}" = "deb" ]; then
                        cd debian
                        dpkg-scanpackages main /dev/null > main/Packages
                        gzip -k main/Packages
                    elif [ "${params.PACKAGE_TYPE}" = "rpm" ]; then
                        cd rpm
                        createrepo .
                    fi
                '''
                
                archiveArtifacts artifacts: 'debian/**,rpm/**', fingerprint: true
            }
        }
        
        stage('Publish Packages') {
            when {
                expression { return env.BRANCH_NAME == 'main' || env.BRANCH_NAME =~ /^v[0-9]+\\.[0-9]+\\.[0-9]+$/ }
            }
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                        # Publish packages to GitHub Packages registry
                        for pkg in release-artifacts/*.deb release-artifacts/*.rpm; do
                            if [ -f "$pkg" ]; then
                                pkg_name=$(basename $pkg)
                                pkg_version=$(echo $pkg_name | grep -oP '(?<=_)[0-9]+\\.[0-9]+\\.[0-9]+(?=_)')
                                if [ -z "$pkg_version" ]; then
                                    pkg_version="${params.KUBE_VERSION}"
                                    pkg_version="${pkg_version#v}"
                                fi
                                
                                echo "Publishing $pkg_name with version $pkg_version"
                                
                                # Get repository information
                                REPO_URL=$(git config --get remote.origin.url)
                                REPO_NAME=$(echo $REPO_URL | sed -n 's/.*github.com[:\/]\\(.*\\)\\.git/\\1/p')
                                ORG_NAME=$(echo $REPO_NAME | cut -d '/' -f 1)
                                
                                # Use GitHub API to publish the package
                                curl -X POST \\
                                    -H "Authorization: token $GITHUB_TOKEN" \\
                                    -H "Accept: application/vnd.github.v3+json" \\
                                    -H "Content-Type: application/octet-stream" \\
                                    --data-binary @"$pkg" \\
                                    "https://api.github.com/orgs/$ORG_NAME/packages/generic/kubernetes-packages/$pkg_version/$pkg_name"
                            fi
                        done
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build completed successfully!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
