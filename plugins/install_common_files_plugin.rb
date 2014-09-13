require 'files'

class InstallCommonFilesPlugin
  def self.title
    "Install common files."
  end

  def run
    Files.install_common_files!
  end
end
