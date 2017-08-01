# module used to check two products for equality
# works for both zypper and registration server originated products
module SUSE::Toolkit::Identifier
  def identifier_triple
    [identifier, version, arch].join('/')
  end
end
