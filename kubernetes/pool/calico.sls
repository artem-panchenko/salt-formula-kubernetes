{%- from "kubernetes/map.jinja" import pool with context %}
{%- if pool.enabled %}

/tmp/calico/:
  file.directory:
      - user: root
      - group: root

copy-calico-ctl:
  dockerng.running:
    - image: {{ pool.network.calicoctl.image }}
    - entrypoint: cat
    - tty: True
    - force: True
    - require:
        - file: /tmp/calico/
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

copy-calico-ctl-cmd:
  dockerng.copy_from:
    - name: copy-calico-ctl
    - source: calicoctl
    - dest: /tmp/calico/
    - require:
      - dockerng: copy-calico-ctl
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/usr/bin/calicoctl:
  file.managed:
    - source: /tmp/calico/calicoctl
    - mode: 751
    - user: root
    - group: root
    - require:
      - cmd: copy-calico-ctl-cmd
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

copy-calico-node:
  dockerng.running:
    - image: {{ pool.network.get('image', 'calico/node') }}
    - entrypoint: cat
    - tty: True
    - force: True
    - require:
        - file: /tmp/calico/
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

copy-bird-cl-cmd:
  dockerng.copy_from:
    - name: copy-calico-node
    - source: /bin/birdcl
    - dest: /tmp/calico/
    - require:
      - dockerng: copy-calico-node
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

/usr/bin/birdcl:
  file.managed:
    - source: /tmp/calico/birdcl
    - mode: 751
    - user: root
    - group: root
    - require:
      - cmd: copy-bird-cl-cmd
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

copy-calico-cni:
  dockerng.running:
    - image: {{ pool.network.cni.image }}
    - entrypoint: cat
    - tty: True
    - force: True
    - require:
        - file: /tmp/calico/
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

copy-calico-cni-cmd:
  dockerng.copy_from:
    - name: copy-calico-cni
    - source: /opt/cni/bin/
    - dest: /tmp/calico/
    - require:
      - dockerng: copy-calico-cni
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- for filename in ['calico', 'calico-ipam'] %}

/opt/cni/bin/{{ filename }}:
  file.managed:
    - source: /tmp/calico/bin/{{ filename }}
    - mode: 751
    - makedirs: true
    - user: root
    - group: root
    - require:
      - dockerng: copy-calico-cni
    - require_in:
      - service: calico_node
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- endfor %}

/etc/cni/net.d/10-calico.conf:
  file.managed:
    - source: salt://kubernetes/files/calico/calico.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/etc/calico/network-environment:
  file.managed:
    - source: salt://kubernetes/files/calico/network-environment.pool
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

/etc/calico/calicoctl.cfg:
  file.managed:
    - source: salt://kubernetes/files/calico/calicoctl.cfg.pool
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - template: jinja

{%- if pool.network.get('systemd', true) %}

/etc/systemd/system/calico-node.service:
  file.managed:
    - source: salt://kubernetes/files/calico/calico-node.service.pool
    - user: root
    - group: root
    - template: jinja

calico_node:
  service.running:
    - name: calico-node
    - enable: True
    - watch:
      - file: /etc/systemd/system/calico-node.service
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- endif %}

{%- endif %}
