# This file is part of Joomla VS.

# Joomla VS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Joomla VS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Joomla VS.  If not, see <http://www.gnu.org/licenses/>.

require 'spec_helper'

describe FingerprintScanner do
  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }
  let(:opts_threads) { 20 }

  let(:typhoeus_code) { 200 }
  let(:typhoeus_body) { '' }
  let(:typhoeus_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }

  before :each do
    @scanner = FingerprintScanner.new(target_uri, {
      :user_agent => opts_user_agent,
      :threads => opts_threads
    })

    Typhoeus.stub(/.*/) do
      Typhoeus::Response.new(code: typhoeus_code, body: typhoeus_body, headers: typhoeus_headers)
    end
  end

  describe '#version_from_readme' do
    context 'when a valid version number is in the README.txt file' do
      let(:typhoeus_body) { '* Joomla! 3.4 version history - https://docs.joomla.org/Joomla_3.4_version_history' }
      it 'returns the version number from the file' do
        expect(@scanner.version_from_readme).to eq '3.4'
      end
    end

    context 'when no version number appears in the README.txt file' do
      let(:typhoeus_body) { 'This is not the readme you are looking for.' }
      it 'returns nil' do
        expect(@scanner.version_from_readme).to be_nil
      end
    end
  end

  describe '#version_from_meta_tag' do
    context 'when a valid version number is in the meta tag' do
      let(:typhoeus_body) { 
        %(
          <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb" lang="en-gb" >
          <head>
            <meta name="robots" content="index, follow" />
            <meta name="description" content="Joomla! Forum" />
            <meta name="generator" content="Joomla! 1.5 - Open Source Content Management" />
          </head>
          </html>
        ) 
      }

      it 'returns the version number from the meta tag' do
        expect(@scanner.version_from_meta_tag).to eq '1.5'
      end
    end

    context 'when no version number appears in the meta tag' do
      let(:typhoeus_body) { 
        %(
          <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb" lang="en-gb" >
          <head>
            <meta name="robots" content="index, follow" />
            <meta name="description" content="Joomla! Forum" />
            <meta name="generator" content="This is not the readme you are looking for." />
          </head>
          </html>
        ) 
      }
      it 'returns nil' do
        expect(@scanner.version_from_meta_tag).to be_nil
      end
    end

    context 'when no generator meta tag is present' do
      let(:typhoeus_body) { 
        %(
          <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb" lang="en-gb" >
          <head>
            <meta name="robots" content="index, follow" />
            <meta name="description" content="Joomla! Forum" />
          </head>
          </html>
        ) 
      }
      it 'returns nil' do
        expect(@scanner.version_from_meta_tag).to be_nil
      end
    end
  end

  describe '#user_registration_enabled' do
    context 'when the response code is 200' do
      let(:typhoeus_code) { 200 }
      it 'returns true' do
        expect(@scanner.user_registration_enabled).to eq true
      end
    end

    context 'when the response code != 200' do
      let(:typhoeus_code) { 301 }
      it 'returns false' do
        expect(@scanner.user_registration_enabled).to eq false
      end
    end
  end

  describe '#directory_listing_enabled' do
    context 'when the served page doesn\'t have a title starting with "Index of"' do
      let(:typhoeus_code) { 200 }
      let(:typhoeus_body) { '<html><head><title>Not the index you are looking for</title></head><body /></html>' }
      it 'returns false' do
        expect(@scanner.directory_listing_enabled('/secret/')).to eq false
      end
    end

    context 'when the served page has a title starting with "Index of"' do
      let(:typhoeus_code) { 200 }
      let(:typhoeus_body) { '<html><head><title>Index of secret</title></head><body /></html>' }
      it 'returns true' do
        expect(@scanner.directory_listing_enabled('/secret/')).to eq true
      end
    end

    context 'when the response code != 200' do
      let(:typhoeus_code) { 404 }
      it 'returns false' do
        expect(@scanner.directory_listing_enabled('/secret/')).to eq false
      end
    end
  end

  describe '#extract_extension_list_from_page' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of strings matching the specified pattern' do
      res = @scanner.extract_extension_list_from_page('/', /com_[a-z0-9\-_]+/i)
      expect(res).to eq ['com_foo', 'com_bar']
    end
  end

  describe '#extract_components_from_admin_index' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of the component names, minus the com_ prefix' do
      res = @scanner.extract_components_from_admin_index
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_components_from_index' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of the component names, minus the com_ prefix' do
      res = @scanner.extract_components_from_index
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_components_from_home' do
    let(:typhoeus_body) { 'Index of page com_foo<br /> com_bar' }
    it 'returns a list of the component names, minus the com_ prefix' do
      res = @scanner.extract_components_from_home
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_modules_from_admin_index' do
    let(:typhoeus_body) { 'Index of page mod_foo<br /> mod_bar' }
    it 'returns a list of the module names, minus the mod_ prefix' do
      res = @scanner.extract_modules_from_admin_index
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_modules_from_index' do
    let(:typhoeus_body) { 'Index of page mod_foo<br /> mod_bar' }
    it 'returns a list of the module names, minus the mod_ prefix' do
      res = @scanner.extract_modules_from_index
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_modules_from_home' do
    let(:typhoeus_body) { 'Index of page mod_foo<br /> mod_bar' }
    it 'returns a list of the module names, minus the mod_ prefix' do
      res = @scanner.extract_modules_from_home
      expect(res).to eq ['foo', 'bar']
    end
  end

  describe '#extract_templates_from_admin_index' do
    let(:typhoeus_body) { %(
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
      <html>
       <head>
        <title>Index of /administrator/templates</title>
       </head>
       <body>
      <h1>Index of /administrator/templates</h1>
        <table>
         <tr><th valign="top"><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr>
         <tr><th colspan="5"><hr></th></tr>
      <tr><td valign="top"><img src="/icons/back.gif" alt="[PARENTDIR]"></td><td><a href="/administrator/">Parent Directory</a></td><td>&nbsp;</td><td align="right">  - </td><td>&nbsp;</td></tr>
      <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="hathor/">hathor/</a></td><td align="right">2015-07-02 16:34  </td><td align="right">  - </td><td>&nbsp;</td></tr>
      <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="isis/">isis/</a></td><td align="right">2015-07-02 16:34  </td><td align="right">  - </td><td>&nbsp;</td></tr>
      <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="system/">system/</a></td><td align="right">2015-07-02 16:34  </td><td align="right">  - </td><td>&nbsp;</td></tr>
         <tr><th colspan="5"><hr></th></tr>
      </table>
      </body></html>
    ) }

    it 'returns a list of possible template names' do
      res = @scanner.extract_templates_from_admin_index
      expect(res).to eq ['administrator', 'hathor', 'isis', 'system']
    end
  end

  describe '#extract_templates_from_index' do
    let(:typhoeus_body) { %(
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
      <html>
       <head>
        <title>Index of /templates</title>
       </head>
       <body>
      <h1>Index of /templates</h1>
        <table>
         <tr><th valign="top"><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr>
         <tr><th colspan="5"><hr></th></tr>
      <tr><td valign="top"><img src="/icons/back.gif" alt="[PARENTDIR]"></td><td><a href="/">Parent Directory</a></td><td>&nbsp;</td><td align="right">  - </td><td>&nbsp;</td></tr>
      <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="hathor/">hathor/</a></td><td align="right">2015-07-02 16:34  </td><td align="right">  - </td><td>&nbsp;</td></tr>
      <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="isis/">isis/</a></td><td align="right">2015-07-02 16:34  </td><td align="right">  - </td><td>&nbsp;</td></tr>
      <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="system/">system/</a></td><td align="right">2015-07-02 16:34  </td><td align="right">  - </td><td>&nbsp;</td></tr>
         <tr><th colspan="5"><hr></th></tr>
      </table>
      </body></html>
    ) }

    it 'returns a list of possible template names' do
      res = @scanner.extract_templates_from_index
      expect(res).to eq ['hathor', 'isis', 'system']
    end
  end

  describe '#extract_templates_from_home' do
    let(:typhoeus_body) { %(
      <!DOCTYPE html>
      <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb" lang="en-gb" dir="ltr">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <base href="http://localhost/" />
        <meta http-equiv="content-type" content="text/html; charset=utf-8" />
        <meta name="generator" content="Joomla! - Open Source Content Management  - Version 3.4.3" />
        <title>Home</title>
        <link href="http://localhost/index.php" rel="canonical" />
        <link href="/index.php?format=feed&amp;type=rss" rel="alternate" type="application/rss+xml" title="RSS 2.0" />
        <link href="/index.php?format=feed&amp;type=atom" rel="alternate" type="application/atom+xml" title="Atom 1.0" />
        <link href="/templates/protostar/favicon.ico" rel="shortcut icon" type="image/vnd.microsoft.icon" />
        <link rel="stylesheet" href="/templates/protostar/css/template.css" type="text/css" />
      </head>
        
      </body>
      </html>
      )}
    it 'returns a list of possible templates from links found in the page source' do
      res = @scanner.extract_templates_from_home
      expect(res).to eq ['protostar']
    end
  end
end