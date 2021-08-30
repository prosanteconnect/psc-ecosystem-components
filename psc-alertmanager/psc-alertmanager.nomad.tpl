job "psc-alertmanager" {
  datacenters = ["dc1"]
  type = "service"

  vault {
    policies = ["psc-ecosystem"]
    change_mode = "restart"
  }

  group "alerting" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    network {
      mode = "host"
      port "alertmanager_ui" {
        to = "9093"
      }
    }

    task "psc-alertmanager" {
      driver = "docker"
      config {
        image = "${image}:${tag}"
        volumes = [
          "local/alertmanager.yml:/etc/alertmanager/alertmanager.yml",
          "local/email.tmpl:/etc/alertmanager/template/email.tmpl",
        ]
        args = [
          "--config.file=/etc/alertmanager/alertmanager.yml",
          "--web.external-url=http://${public_hostname}/"
        ]
        ports = [
          "alertmanager_ui"
        ]
      }

      artifact {
        mode = "file" // otherwise it will fail with mode 'any'
        source = "https://raw.githubusercontent.com/prosanteconnect/psc-ecosystem-components/main/psc-alertmanager/email.tmpl"
        destination = "local/email.tmpl"
      }

      template {
        change_mode = "restart"
        destination = "local/alertmanager.yml"
        data = <<EOH
global:
  resolve_timeout: 1m

templates :
- /etc/alertmanager/template/email.tmpl

route:
  receiver: 'gmail-notifications'
  routes:
  - receiver: 'pscload-webhook'
    matchers:
    - severity="pscload-OK"
  - receiver: 'gmail-notifications'
    matchers:
    - severity="critical"

receivers:
- name: 'default-receiver'
- name: 'gmail-notifications'
  email_configs:
  - to: testdev.ans@gmail.com
    from: prosanteconnect.ans@gmail.com
    smarthost: smtp.gmail.com:587
    auth_username: prosanteconnect.ans@gmail.com
    auth_identity: prosanteconnect.ans@gmail.com
    auth_password: iuhikcrcelpkhoqw
    send_resolved: true
    html : {{ `'{{ template "email.custom.html" . }}'` }}
- name: 'pscload-webhook'
  email_configs:
  - to: testdev.ans@gmail.com
    from: prosanteconnect.ans@gmail.com
    smarthost: smtp.gmail.com:587
    auth_username: prosanteconnect.ans@gmail.com
    auth_identity: prosanteconnect.ans@gmail.com
    auth_password: {{ with secret "psc-ecosystem/alertmanager" }}{{ .Data.data.auth_password }}{{ end }}
    send_resolved: true
    html : {{ `'{{ template "email.custom.html" . }}'` }}
  webhook_configs:
  - url: http://{{ range service "pscload" }}{{ .Address }}:{{ .Port }}{{ end }}/pscload/v1/process/continue
EOH
      }

      resources {
        cpu = 500
        memory = 1024
      }

      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D"
        tags = ["urlprefix-${public_hostname}/psc-alertmanager strip=/psc-alertmanager"]
        port = "alertmanager_ui"
        check {
          name     = "alertmanager_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
