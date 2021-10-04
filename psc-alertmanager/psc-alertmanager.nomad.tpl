job "psc-alertmanager" {
  datacenters = ["${datacenter}"]
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
          "--web.external-url=http://$\u007BPUBLIC_HOSTNAME\u007D/"
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
        destination = "local/email.tmpl"
        change_mode = "restart"
        data = <<EOH
{{ `{{ define "email.custom.html" }}` }}
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/1999/xhtml" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
<head style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
  <meta name="viewport" content="width=device-width" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />
  <title style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">{{ `{{ template "__subject" . }}` }}</title>

</head>

<body itemscope="" itemtype="http://schema.org/EmailMessage" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; -webkit-font-smoothing: antialiased; -webkit-text-size-adjust: none; height: 100%; line-height: 1.6em; width: 100% !important; background-color: #f6f6f6; margin: 0; padding: 0;" bgcolor="#f6f6f6">

<table style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; width: 100%; background-color: #f6f6f6; margin: 0;" bgcolor="#f6f6f6">
  <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
    <td width="600" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; display: block !important; max-width: 600px !important; clear: both !important; width: 100% !important; margin: 0 auto; padding: 0;" valign="top">
      <div style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; max-width: 600px; display: block; margin: 0 auto; padding: 0;">
        <table width="100%" cellpadding="0" cellspacing="0" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; border-radius: 3px; background-color: #fff; margin: 0; border: 1px solid #e9e9e9;" bgcolor="#fff">
          <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
            <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 16px; vertical-align: top; color: #fff; font-weight: 500; text-align: center; border-radius: 3px 3px 0 0; background-color: #E6522C; margin: 0; padding: 20px;" align="center" bgcolor="#E6522C" valign="top">
              Alerte différentiel PSC-LOAD
            </td>
          </tr>
          <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
            <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 10px;" valign="top">
              <table width="100%" cellpadding="0" cellspacing="0" style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                  <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                    <a href="https://forge.psc.henix.asipsante.fr/prometheus/graph?g0.expr=ps_metric%7Bgroup%3D~%22total%7C0%7C3%7C5%7C8%22%2Coperation%3D~%22create%7Cupdate%7Cdelete%22%7D&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1w"
                       style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px;
                    color: #FFF; text-decoration: none; line-height: 2em; font-weight: bold; text-align: center; cursor: pointer;
                    display: inline-block; border-radius: 5px; text-transform: capitalize; background-color: #348eda; margin: 0; border-color: #348eda;
                    border-style: solid; border-width: 10px 20px;">Consulter Prometheus</a>
                  </td>
                </tr>

                {{ `{{ range .Alerts }}` }}
                <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                  <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                    {{ `{{ if gt (len .Annotations) 0 }}` }}<strong style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0; padding: 0 0 20px;">Annotations</strong>
                    <br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ `{{ end }}` }}
                    {{ `{{ range .Annotations.SortedPairs }}` }}{{ `{{ .Name }}` }} = {{ `{{ .Value }}` }}
                    <br style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;" />{{ `{{ end }}` }}
                  </td>
                </tr>

                <tr style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; margin: 0;">
                  <td style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px; vertical-align: top; margin: 0; padding: 0 0 20px;" valign="top">
                    <form action="https://pscload.psc.api.esante.gouv.fr/pscload/v1/process/continue" method="post">
                      <input type="submit" name="continue" value="Continuer le processus" formmethod="post"
                             formtarget="display-frame"
                             style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; box-sizing: border-box; font-size: 14px;
                      color: #FFF; text-decoration: none; line-height: 2em; font-weight: bold; text-align: center; cursor: pointer;
                      display: inline-block; border-radius: 5px; text-transform: capitalize; background-color: #348eda; margin: 0; border-color: #348eda;
                      border-style: solid; border-width: 10px 20px;"/>
                    </form>
                  </td>
                </tr>

                <iframe name="display-frame" style="width:100%;height:600px;border:2px solid #348eda;"></iframe>

                {{ `{{ end }}` }}
              </table>
            </td>
          </tr>
        </table>
      </div>
    </td>
  </tr>
</table>

</body>
</html>

{{ `{{ end }}` }}
EOH
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
      template {
        change_mode = "restart"
        destination = "local/file.env"
        env = true
        data = <<EOF
PUBLIC_HOSTNAME={{ with secret "psc-ecosystem/alertmanager" }}{{ .Data.data.public_hostname }}{{ end }}
EOF
      }

      resources {
        cpu = 500
        memory = 1024
      }

      service {
        name = "$\u007BNOMAD_JOB_NAME\u007D"
        tags = ["urlprefix-$\u007BPUBLIC_HOSTNAME\u007D/psc-alertmanager strip=/psc-alertmanager"]
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
