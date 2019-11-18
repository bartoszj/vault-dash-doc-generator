require "nokogiri"
require "erb"
require "sqlite3"
require "pathname"

class Index
  attr_accessor :db

  def initialize(path)
    @db = SQLite3::Database.new path
  end

  def drop
    @db.execute <<-SQL
      DROP TABLE IF EXISTS searchIndex
    SQL
  end

  def create
    db.execute <<-SQL
      CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)
    SQL
    db.execute <<-SQL
      CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path)
    SQL
  end

  def reset
    drop
    create
  end

  def insert(type, path)
    doc = Nokogiri::HTML(File.open(path).read)
    if doc.title.nil?
      return
    end
    name = doc.title.sub(" - Vault by HashiCorp", "").sub(/.*: (.*)/, "\\1")
    @db.execute <<-SQL, name: name, type: type, path: path
      INSERT OR IGNORE INTO searchIndex (name, type, path)
      VALUES(:name, :type, :path)
    SQL
  end
end

task default: [:clean, :build, :setup, :copy, :create_index, :package]

task :clean do
  rm_rf "build"
  rm_rf "Vault.docset"
end

task :build do
  config_extensions = ["activate :relative_assets", "set :relative_links, true", "set :strip_index_file, false"]
  File.open("config.rb", "a") do |f|
    config_extensions.each do |ce|
      if File.readlines("config.rb").grep(Regexp.new ce).size == 0
        f.puts ce
      end
    end
  end

  sh "sh bootstrap.sh" if File.exists?("bootstrap.sh")
  sh "bundle"
  sh "bundle exec middleman build"
  # sh "bundle exec middleman build --no-parallel"
end

task :setup do
  mkdir_p "Vault.docset/Contents/Resources/Documents"

  # Icon
  # at older docs there is no retina icon
  if File::exist? "source/assets/images/favicons/favicon-16x16.png" and File::exist? "source/assets/images/favicons/favicon-32x32.png"
    cp "source/assets/images/favicons/favicon-16x16.png", "Vault.docset/icon.png"
    cp "source/assets/images/favicons/favicon-32x32.png", "Vault.docset/icon@2x.png"
  elsif File::exist? "source/assets/images/logo-icon.png" and File::exist? "source/assets/images/logo-icon@2x.png"
    cp "source/assets/images/logo-icon.png", "Vault.docset/icon.png"
    cp "source/assets/images/logo-icon@2x.png", "Vault.docset/icon@2x.png"
  elsif File::exist? "assets/img/favicons/favicon-16x16.png" and File::exist? "assets/img/favicons/favicon-32x32.png"
    cp "assets/img/favicons/favicon-16x16.png", "Vault.docset/icon.png"
    cp "assets/img/favicons/favicon-32x32.png", "Vault.docset/icon@2x.png"
  else
    abort("Icon not found")
  end

  # Info.plist
  File.open("Vault.docset/Contents/Info.plist", "w") do |f|
    f.write <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
    <key>CFBundleIdentifier</key>
    <string>vault</string>
    <key>CFBundleName</key>
    <string>Vault</string>
    <key>DocSetPlatformFamily</key>
    <string>vault</string>
    <key>isDashDocset</key>
    <true/>
    <key>DashDocSetFamily</key>
    <string>dashtoc</string>
    <key>dashIndexFilePath</key>
    <string>docs/index.html</string>
    <key>DashDocSetFallbackURL</key>
    <string>https://www.vaultproject.io/</string>
    </dict>
</plist>
    XML
  end
end

task :copy do
  file_list = []
  Dir.chdir("build") { file_list = Dir.glob("**/*").sort }

  file_list.each do |path|
    source = "build/#{path}"
    target = "Vault.docset/Contents/Resources/Documents/#{path}"

    case
    when File.stat(source).directory?
      mkdir_p target
    when source.match(/\.gz$/)
      next
    when source.match(/\.html$/)
      doc = Nokogiri::HTML(File.open(source).read)

      unless doc.title.nil?
        doc.title = doc.title.sub(" - Vault by HashiCorp", "")
        doc.title = doc.title.sub(" - HTTP API", "")
      end

      doc.xpath("//a[contains(@class, 'anchor')]").each do |e|
        a = Nokogiri::XML::Node.new "a", doc
        a["class"] = "dashAnchor"
        a["name"] = "//apple_ref/cpp/%{type}/%{name}" %
          {type: "Section", name: ERB::Util.url_encode(e.parent.children.last.text.strip)}
        e.previous = a
      end

      doc.xpath("//a[starts-with(@href, '/')]").each do |e|
        e["href"] = Pathname.new(e["href"]).relative_path_from(Pathname.new("/#{path}").dirname).to_s
      end

      doc.xpath('//script').each do |script|
        if script.text != ""
          script.remove
        end
      end
      doc.xpath("id('header')").each do |e|
        e.remove
      end
      doc.xpath("//nav[contains(@class, 'g-mega-nav')]").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'mega-nav-sandbox')]").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'g-product-subnav')]").each do |e|
        e.remove
      end
      doc.xpath("//div[contains(@class, 'docs-sidebar')]").each do |e|
        e.parent.remove
      end
      doc.xpath("id('docs-sidebar')").each do |e|
        e.remove
      end
      doc.xpath("id('sidebar')").each do |e|
        e.remove
      end
      doc.xpath("id('consent-manager')").each do |e|
        e.remove
      end
      doc.xpath("id('footer')").each do |e|
        e.remove
      end
      doc.xpath("//footer").each do |e|
        e.remove
      end

      doc.xpath('//div[@id="inner"]/h1').each do |e|
        e["style"] = "margin-top: 0px"
      end
      doc.xpath("//div[contains(@class, 'content-wrap')]").each do |e|
        e["class"] = e["class"].sub("content-wrap", "")
      end
      doc.xpath("//div[contains(@role, 'main')]").each do |e|
        e["style"] = "width: 100%"
      end

      File.open(target, "w") { |f| f.write doc }
    else
      cp source, target
    end
  end
end

task :create_index do
  index = Index.new("Vault.docset/Contents/Resources/docSet.dsidx")
  index.reset

  Dir.chdir("Vault.docset/Contents/Resources/Documents") do
    # intro/getting-started
    Dir.glob("intro/getting-started/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      if path.match(/\.html$/)
        index.insert "Guide", path
      end
    end
    # guides
    Dir.glob("guides/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      if path.match(/\.html$/)
        index.insert "Guide", path
      end
    end
    # docs/agent
    Dir.glob("docs/agent/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Setting", path
    end
    # docs/audit
    Dir.glob("docs/audit/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Setting", path
    end
    # docs/auth
    Dir.glob("docs/auth/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Setting", path
    end
    # docs/commands
    Dir.glob("docs/commands/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Command", path
    end
    # docs/connect
    Dir.glob("docs/connect/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Setting", path
    end
    # docs/configuration
    Dir.glob("docs/configuration/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Setting", path
    end
    # docs/enterprise
    Dir.glob("docs/enterprise/**/*")
      .find_all{ |f| File.stat(f).file? and File.extname(f) == ".html" }.each do |path|

      index.insert "Environment", path
    end
    # docs/install
    Dir.glob("docs/install/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Instruction", path
    end
    # docs/internals
    Dir.glob("docs/internals/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Instruction", path
    end
    # docs/partnerships
    Dir.glob("docs/partnerships/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Instruction", path
    end
    # docs/plugin
    Dir.glob("docs/plugin/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Plugin", path
    end
    # docs/secrets
    Dir.glob("docs/secrets/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Setting", path
    end
    # docs/upgrading
    Dir.glob("docs/upgrading/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Instruction", path
    end
    # docs/use-cases
    Dir.glob("docs/use-cases/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # docs/vs
    Dir.glob("docs/vs/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # docs/what-is-vault
    Dir.glob("docs/what-is-vault/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Guide", path
    end
    # api
    Dir.glob("api/**/*")
      .find_all{ |f| File.stat(f).file? }.each do |path|

      index.insert "Define", path
    end
  end
end

task :import do
  sh "open Vault.docset"
end

task :package do
  sh "tar --exclude='.DS_Store' -cvzf Vault.tgz Vault.docset"
end
