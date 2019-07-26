#! /bin/bash -e

# At this point, filesystem should be mounted /var/jenkins_home,
# if ever it is configured to mount there.
# So, put back files backed-up from /var/jenkins_home.
shopt -s dotglob nullglob # Let the loop include hidden files.
for item in /tmp/jenkins_home_contents/*; do
  filename=$(basename $item)
  if [[ ! -e /var/jenkins_home/$filename ]]; then
    mv $item /var/jenkins_home/
  fi
done
shopt -u dotglob nullglob
rm -rf /tmp/jenkins_home_contents

/sbin/tini -- /usr/local/bin/jenkins.sh
