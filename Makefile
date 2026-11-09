STREAMS   := core comm sc gov
SITES     := ruh jed
INVENTORY ?= inventory.ini
PLAYBOOK  := connectivity-check.yml

# second word of "make <stream> <site>"
SITE := $(filter $(SITES),$(word 2,$(MAKECMDGOALS)))

.PHONY: all $(STREAMS) $(SITES)

# everything
all:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

# make comm / make comm ruh
$(STREAMS):
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) -e stream=$@ $(if $(SITE),-e site=$(SITE))

# make ruh (site only, all streams); as second word it is a no-op goal
$(SITES):
	@if [ "$(word 1,$(MAKECMDGOALS))" = "$@" ]; then \
	  ansible-playbook -i $(INVENTORY) $(PLAYBOOK) -e site=$@; \
	fi
