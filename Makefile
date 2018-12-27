default: latest intel nvidia

# =====
# TOOLS
# =====

tools-latest: tools-intel
	docker tag diegoferigo/tools:intel diegoferigo/tools:latest

tools-intel:
	docker build --rm --pull \
		--build-arg from=diegoferigo/devenv:intel \
		--tag diegoferigo/tools:intel \
		Tools/

tools-nvidia:
	docker build --rm --pull \
	--build-arg from=diegoferigo/devenv:nvidia \
	--tag diegoferigo/tools:nvidia \
	Tools/

# ===========
# DEVELOPMENT
# ===========

development-latest: development-intel-master
	docker tag diegoferigo/development:intel-master diegoferigo/development:latest

development-intel-master:
	docker build --rm \
		--build-arg from=diegoferigo/tools:intel \
		--tag diegoferigo/development:intel-master \
		--build-arg SOURCES_GIT_BRANCH=master \
		Development/

development-nvidia-master:
	docker build --rm \
		--build-arg from=diegoferigo/tools:nvidia \
		--tag diegoferigo/development:nvidia-master \
		--build-arg SOURCES_GIT_BRANCH=master \
		Development/

development-intel-devel:
	docker build --rm \
		--build-arg from=diegoferigo/tools:intel \
		--tag diegoferigo/development:intel-devel \
		--build-arg SOURCES_GIT_BRANCH=devel \
		Development/

development-nvidia-devel:
	docker build --rm \
		--build-arg from=diegoferigo/tools:nvidia \
		--tag diegoferigo/development:nvidia-devel \
		--build-arg SOURCES_GIT_BRANCH=devel \
		Development/

# ======================
# REINFORCEMENT LEARNING
# ======================

rl-nvidia-master:
	docker build --rm \
		--build-arg from=diegoferigo/development:nvidia-master \
		--tag diegoferigo/rl:nvidia-master \
		RL/

# ======
# DEPLOY
# ======

push-tools-latest: tools-latest
	docker push diegoferigo/tools:latest

push-tools-intel: tools-intel
	docker push diegoferigo/tools:intel

push-tools-nvidia: tools-nvidia
	docker push diegoferigo/tools:nvidia

push-development-latest: development-latest
	docker push diegoferigo/development:latest

push-development-intel-master: development-intel-master
	docker push diegoferigo/development/intel-master

push-development-intel-devel: development-intel-devel
	docker push diegoferigo/development:intel-devel

push-development-nvidia-master: development-nvidia-master
	docker push diegoferigo/development/nvidia-master

push-development-nvidia-devel: development-nvidia-devel
	docker push diegoferigo/development:nvidia-devel
