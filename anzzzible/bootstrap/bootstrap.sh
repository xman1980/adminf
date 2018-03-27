#!/bin/bash
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i newhosts --ask-pass -vvvv bootstrap.yml