class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{ORG_MAILER_DOMAIN}"
  layout 'mailer'
end
