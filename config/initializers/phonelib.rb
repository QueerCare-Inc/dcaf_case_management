Phonelib.default_country = 'US'
Phonelib.vanity_conversion = true
Phonelib.strict_check = true
Phonelib.sanitize_regex = '[\.\-\(\) \;\+]'
Phonelib.extension_separator = ';'

Phonelib.extension_separate_symbols = '#;'           # for single symbol separator
Phonelib.extension_separate_symbols = %w(ext # ; extension) # each string will be treated as separator

Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[0]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[1]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[2]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[3]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[4]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[5]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[6]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[7]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[8]{10}' # this will add number 1-555-555-5555 to be valid
Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '[9]{10}' # this will add number 1-555-555-5555 to be valid