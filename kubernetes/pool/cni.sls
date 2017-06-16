{%- from "kubernetes/map.jinja" import pool with context %}
{%- from "kubernetes/map.jinja" import common with context %}
{%- if pool.enabled %}

{%- if common.hyperkube %}

/tmp/cni/:
  file.directory:
    - user: root
    - group: root

copy-network-cni:
  dockerng.running:
    - image: {{ common.hyperkube.image }}
    - entrypoint: cat
    - tty: True
    - force: True
    - require:
        - file: /tmp/cni/
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

copy-network-cni-cmd:
  cmd.run:
    - name: docker cp copy-network-cni:/opt/cni/bin/ /tmp/cni/
    - require:
      - dockerng: copy-network-cni
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- for filename in ['cnitool', 'flannel', 'tuning', 'bridge', 'ipvlan', 'loopback', 'macvlan', 'ptp', 'dhcp', 'host-local', 'noop'] %}
/opt/cni/bin/{{ filename }}:
  file.managed:
    - source: /tmp/cni/bin/{{ filename }}
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
    - watch_in:
      - service: kubelet_service
    - require:
      - cmd: copy-network-cni-cmd
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}

{%- endfor %}

{%- endif %}

{%- endif %}
