module Exceptions
  class UnauthorizedError < StandardError; end

  class NoGoogleGeoApiKeyError < StandardError; end

  class NoRegionsForOrgError < StandardError; end
end
