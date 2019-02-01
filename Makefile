default: latest intel nvidia

# =====
# TOOLS
# =====

tools:
	docker build --rm \
	--build-arg from=diegoferigo/devenv:nvidia \
	--tag diegoferigo/tools \
	Tools/

# ===========
# DEVELOPMENT
# ===========

development-latest: development-master
	docker tag diegoferigo/development:master diegoferigo/development:latest

development-master:
	docker build --rm \
		--build-arg from=diegoferigo/tools \
		--tag diegoferigo/development:master \
		--build-arg SOURCES_GIT_BRANCH=master \
		Development/

development-devel:
	docker build --rm \
		--build-arg from=diegoferigo/tools \
		--tag diegoferigo/development:devel \
		--build-arg SOURCES_GIT_BRANCH=devel \
		Development/

# ======================
# REINFORCEMENT LEARNING
# ======================

rl-latest: rl-master
	docker tag diegoferigo/rl:master diegoferigo/rl:latest

rl-master:
	docker build --rm \
		--build-arg from=diegoferigo/development:master \
		--tag diegoferigo/rl:master \
		RL/

# ======
# DEPLOY
# ======

push-tools: tools
	docker push diegoferigo/tools

push-development-latest: development-latest
	docker push diegoferigo/development:latest

push-development-master: development-master
	docker push diegoferigo/development:master

push-development-devel: development-devel
	docker push diegoferigo/development:devel

push-rl-latest: rl-latest
	docker push diegoferigo/rl:latest

push-rl-master: rl-master
	docker push diegoferigo/rl:master
