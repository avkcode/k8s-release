import jetbrains.buildServer.configs.kotlin.v2019_2.*
import jetbrains.buildServer.configs.kotlin.v2019_2.buildFeatures.dockerSupport
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.v2019_2.buildSteps.script
import jetbrains.buildServer.configs.kotlin.v2019_2.triggers.vcs
import jetbrains.buildServer.configs.kotlin.v2019_2.vcs.GitVcsRoot

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvn -Dteamcity.development.mode=true compile

command and then use the

    mvn -Dteamcity.development.mode=true jetbrains.buildServer.configs.kotlin.v2019_2:generate

command to generate the resulting XML project.
*/

version = "2023.05"

project {
    description = "Kubernetes Packages Builder"

    vcsRoot(KubernetesPackagesVcs)

    buildType(BuildKubeProxy)
    buildType(BuildKubelet)
    buildType(BuildEtcd)
    buildType(BuildKubeScheduler)
    buildType(BuildKubeControllerManager)
    buildType(BuildKubeApiserver)
    buildType(BuildKubectl)
    buildType(BuildFlannel)
    buildType(BuildCalico)
    buildType(BuildCertificates)
    buildType(PublishPackages)
}

object KubernetesPackagesVcs : GitVcsRoot({
    name = "Kubernetes Packages"
    url = "https://github.com/your-org/kubernetes-packages.git"
    branch = "refs/heads/main"
    branchSpec = """
        +:refs/heads/*
        +:refs/tags/*
    """.trimIndent()
})

object BuildKubeProxy : BuildType({
    name = "Build kube-proxy"
    description = "Build kube-proxy package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build kube-proxy"
            scriptContent = """
                KUBE_VERSION=%KUBE_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-kube-proxy
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildKubelet : BuildType({
    name = "Build kubelet"
    description = "Build kubelet package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build kubelet"
            scriptContent = """
                KUBE_VERSION=%KUBE_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-kubelet
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildEtcd : BuildType({
    name = "Build etcd"
    description = "Build etcd package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("ETCD_VERSION", "v3.5.9")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build etcd"
            scriptContent = """
                ETCD_VERSION=%ETCD_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-etcd
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildKubeScheduler : BuildType({
    name = "Build kube-scheduler"
    description = "Build kube-scheduler package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build kube-scheduler"
            scriptContent = """
                KUBE_VERSION=%KUBE_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-kube-scheduler
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildKubeControllerManager : BuildType({
    name = "Build kube-controller-manager"
    description = "Build kube-controller-manager package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build kube-controller-manager"
            scriptContent = """
                KUBE_VERSION=%KUBE_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-kube-controller-manager
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildKubeApiserver : BuildType({
    name = "Build kube-apiserver"
    description = "Build kube-apiserver package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build kube-apiserver"
            scriptContent = """
                KUBE_VERSION=%KUBE_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-kube-apiserver
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildKubectl : BuildType({
    name = "Build kubectl"
    description = "Build kubectl package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build kubectl"
            scriptContent = """
                KUBE_VERSION=%KUBE_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-kubectl
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildFlannel : BuildType({
    name = "Build flannel"
    description = "Build flannel package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("FLANNEL_VERSION", "v0.26.4")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build flannel"
            scriptContent = """
                FLANNEL_VERSION=%FLANNEL_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-flannel
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildCalico : BuildType({
    name = "Build calico"
    description = "Build calico package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("CALICO_VERSION", "v3.28.0")
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build calico"
            scriptContent = """
                CALICO_VERSION=%CALICO_VERSION% \
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-calico
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object BuildCertificates : BuildType({
    name = "Build certificates"
    description = "Build certificates package"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("PACKAGE_TYPE", "deb")
        param("DOCKER_COMPOSE", "docker compose")
    }

    steps {
        script {
            name = "Build certificates"
            scriptContent = """
                PACKAGE_TYPE=%PACKAGE_TYPE% \
                DOCKER_COMPOSE=%DOCKER_COMPOSE% \
                make build-certificates
            """.trimIndent()
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = "output/*.deb => output/\noutput/*.rpm => output/"
})

object PublishPackages : BuildType({
    name = "Publish Packages"
    description = "Publish packages to GitHub Packages"

    vcs {
        root(KubernetesPackagesVcs)
    }

    params {
        param("KUBE_VERSION", "v1.32.2")
        param("ETCD_VERSION", "v3.5.9")
        param("FLANNEL_VERSION", "v0.26.4")
        param("CALICO_VERSION", "v3.28.0")
        param("PACKAGE_TYPE", "deb")
        password("GITHUB_TOKEN", "credentialsJSON:github-token")
    }

    dependencies {
        snapshot(BuildKubeProxy) {}
        snapshot(BuildKubelet) {}
        snapshot(BuildEtcd) {}
        snapshot(BuildKubeScheduler) {}
        snapshot(BuildKubeControllerManager) {}
        snapshot(BuildKubeApiserver) {}
        snapshot(BuildKubectl) {}
        snapshot(BuildFlannel) {}
        snapshot(BuildCalico) {}
        snapshot(BuildCertificates) {}
    }

    steps {
        script {
            name = "Collect artifacts"
            scriptContent = """
                mkdir -p release-artifacts
                find . -name "*.deb" -o -name "*.rpm" | xargs -I{} cp {} release-artifacts/
            """.trimIndent()
        }
        
        script {
            name = "Create package repositories"
            scriptContent = """
                mkdir -p debian/main rpm
                
                # Copy DEB packages to debian repo structure
                cp release-artifacts/*.deb debian/main/ || true
                
                # Copy RPM packages to rpm repo structure
                cp release-artifacts/*.rpm rpm/ || true
                
                if [ "%PACKAGE_TYPE%" = "deb" ]; then
                    cd debian
                    dpkg-scanpackages main /dev/null > main/Packages
                    gzip -k main/Packages
                elif [ "%PACKAGE_TYPE%" = "rpm" ]; then
                    cd rpm
                    createrepo .
                fi
            """.trimIndent()
        }
        
        script {
            name = "Publish packages to GitHub Packages"
            scriptContent = """
                # Publish packages to GitHub Packages registry
                for pkg in release-artifacts/*.deb release-artifacts/*.rpm; do
                    if [ -f "$pkg" ]; then
                        pkg_name=$(basename $pkg)
                        pkg_version=$(echo $pkg_name | grep -oP '(?<=_)[0-9]+\\.[0-9]+\\.[0-9]+(?=_)')
                        if [ -z "$pkg_version" ]; then
                            pkg_version="%KUBE_VERSION%"
                            pkg_version="\${pkg_version#v}"
                        fi
                        
                        echo "Publishing $pkg_name with version $pkg_version"
                        
                        # Get repository information
                        REPO_URL=$(git config --get remote.origin.url)
                        REPO_NAME=$(echo $REPO_URL | sed -n 's/.*github.com[:\/]\\(.*\\)\\.git/\\1/p')
                        ORG_NAME=$(echo $REPO_NAME | cut -d '/' -f 1)
                        
                        # Use GitHub API to publish the package
                        curl -X POST \
                            -H "Authorization: token %GITHUB_TOKEN%" \
                            -H "Accept: application/vnd.github.v3+json" \
                            -H "Content-Type: application/octet-stream" \
                            --data-binary @"$pkg" \
                            "https://api.github.com/orgs/$ORG_NAME/packages/generic/kubernetes-packages/$pkg_version/$pkg_name"
                    fi
                done
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            branchFilter = "+:refs/heads/main"
        }
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }

    artifactRules = """
        release-artifacts/*.deb => packages/
        release-artifacts/*.rpm => packages/
        debian/** => repositories/debian/
        rpm/** => repositories/rpm/
    """.trimIndent()
})
