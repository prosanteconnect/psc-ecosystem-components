job "psc-alertmanager" {
  datacenters = ["${datacenter}"]
  type = "service"
  namespace = "${nomad_namespace}"

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
          "secrets/alertmanager.yml:/etc/alertmanager/alertmanager.yml",
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
                    <a href="https://{{ with secret "psc-ecosystem/admin" }}{{ .Data.data.admin_public_hostname}}{{ end }}/psc-prometheus/graph"
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
                    <form action="https://{{ with secret "psc-ecosystem/pscload" }}{{ .Data.data.public_hostname}}{{ end }}/pscload/v2/process/continue" method="post">
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
        destination = "secrets/alertmanager.yml"
        data = <<EOH
global:
  resolve_timeout: 1m

templates :
- /etc/alertmanager/template/email.tmpl

route:
  group_by: ['severity']
  receiver: 'email-notifications'
  routes:
  - receiver: 'pscload-webhook'
    matchers:
    - severity="continue"
  - receiver: 'email-notifications'
    matchers:
    - severity="critical"

inhibit_rules:
- source_matchers: [severity="critical"]
  target_matchers: [severity="continue"]

receivers:
- name: 'email-notifications'
  email_configs:
  - to: {{ with secret "psc-ecosystem/${nomad_namespace}/admin" }}{{ .Data.data.mail_receiver}}{{ end }}
    from: {{ with secret "psc-ecosystem/${nomad_namespace}/admin" }}{{ .Data.data.mail_username}}{{ end }}
    smarthost: {{ with secret "psc-ecosystem/${nomad_namespace}/admin" }}{{ .Data.data.mail_server_host}}:{{ .Data.data.mail_server_port}}{{ end }}
    {{ with secret "psc-ecosystem/${nomad_namespace}/admin" }}auth_username: {{ .Data.data.mail_username}}
    auth_identity: {{ .Data.data.mail_username}}
    auth_password: {{ .Data.data.alert_manager_key }}{{ end }}
    send_resolved: true
    require_tls: true
    html : {{ `'{{ template "email.custom.html" . }}'` }}
- name: 'pscload-webhook'
{{ range service "webhooker" }}  webhook_configs:
  - url: http://{{ .Address }}:{{ .Port }}/webhooker{{ end }}
EOH
      }
      template {
        change_mode = "restart"
        destination = "local/file.env"
        env = true
        data = <<EOF
PUBLIC_HOSTNAME={{ with secret "psc-ecosystem/${nomad_namespace}/admin" }}{{ .Data.data.admin_public_hostname }}{{ end }}
EOF
      }

      service {
        name = "$\u007BNOMAD_NAMESPACE\u007D-$\u007BNOMAD_JOB_NAME\u007D"
        tags = ["urlprefix-$\u007BPUBLIC_HOSTNAME\u007D/psc-alertmanager strip=/psc-alertmanager"]
        port = "alertmanager_ui"
        check {
          name     = "alertmanager_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "30s"
          timeout  = "2s"
          failures_before_critical = 5
        }
      }
    }
  }
}
