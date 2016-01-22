# This file is part of JoomlaVS.

# JoomlaVS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# JoomlaVS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with JoomlaVS.  If not, see <http://www.gnu.org/licenses/>.

require 'spec_helper'

describe TemplateScanner do
  let(:target_uri) { 'http://localhost/' }
  let(:opts_user_agent) { 'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0' }

  let(:typhoeus_code) { 200 }
  let(:typhoeus_body) { '' }
  let(:typhoeus_headers) { { 'Content-Type' => 'text/html; charset=utf-8' } }

  before :each do
    @scanner = TemplateScanner.new(
      target_uri,
      user_agent: opts_user_agent,
      threads: 20
    )

    Typhoeus.stub(/.*/) do
      Typhoeus::Response.new(code: typhoeus_code, body: typhoeus_body, headers: typhoeus_headers)
    end
  end

  describe '#possible_paths' do
    it 'returns two possible paths for the template to be found' do
      expect(@scanner.possible_paths('test').length).to eq 2
    end
  end

  describe '#queue_requests' do
    context 'when passed a valid path index' do
      it 'queues a request to be made by hydra' do
        @scanner.queue_requests('foo', 0)
        @scanner.queue_requests('bar', 1)
        expect(@scanner.hydra.queued_requests.length).to eq 2
      end
    end

    context 'when passed an invalid path index' do
      it 'does not queue the request' do
        @scanner.queue_requests('foo', 3)
        @scanner.queue_requests('bar', 4)
        expect(@scanner.hydra.queued_requests.length).to eq 0
      end
    end
  end

  describe '#extract_list_from_admin_index' do
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
      res = @scanner.extract_list_from_admin_index
      expect(res).to eq ['administrator', 'hathor', 'isis', 'system']
    end
  end

  describe '#extract_list_from_index' do
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
      res = @scanner.extract_list_from_index
      expect(res).to eq ['hathor', 'isis', 'system']
    end
  end

  describe '#extract_list_from_home' do
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
      res = @scanner.extract_list_from_home
      expect(res).to eq ['protostar']
    end
  end
end
