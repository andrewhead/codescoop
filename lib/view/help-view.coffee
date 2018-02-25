$ = require "jquery"

HELP_HTML = """
<h1>CodeScoop Demo</h1>

<p>
In this demo, you can try out the interactions introduced in the paper
<span class="paper_name">
<a href="https://codescoop.berkeley.edu/pdfs/example_extraction.pdf">Interactive
Extraction of Examples from Existing Code</a></span>.
</p>

<h2>Step I. Start extracting an example.</h2>

<p>
Start extracting an example from the source program by:
<ol>
  <li>Selecting some text</li>
  <li>Clicking the "Scoop" <span class="icon icon-paintcan"></span>button</li>
</ol>
</p>

<p>
Your selections will be wrapped in a work-in-progress example file that opens on the right.
</p>

<h2>Step II. Fix up the example.</h2>

<p>
Add code to the example by:
<ol class="long-bullets">
  <li><span class="action_name">Resolving issues with CodeScoop's help</span>: Fix <span class="broken_symbols">broken symbols</span> by clicking those symbols, and following prompts to add code or insert literals.</li>
  <li><span class="action_name">Adding code manually</span>: Add any other line by clicking its line number in the gutter of the source program.</li>
</ol>
</p>

<h2>Step III. Other features.</h2>

<p>
Watch this 3-minute demo video to learn about CodeScoop's other features.
</p>

<div class="video-container">
  <iframe class="video" src="https://www.youtube.com/embed/RYbhnRDbvyY?start=60&vq=hd1080" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
</div>

<h2>Questions and Answers</h2>

<h3>What do the buttons do?</h3>

<ul class="long-bullets">
  <li><span class="ul_li"><span class="button_name"><span class="icon icon-mail-reply"></span>Undo</span>: Undo the last action.</span></li>
  <li><span class="ul_li"><span class="button_name"><span class="icon icon-sync"></span>Reset</span>: Delete the example, so you can start a new scoop.</span></li>
  <li><span class="ul_li"><span class="button_name"><span class="icon icon-diff-renamed"></span>Run</span>: Disabled in this online demo; in the full prototype, this lets you compile and run the example.</span></li>
  <li><span class="ul_li"><span class="button_name"><span class="icon icon-info"></span>Show / Hide Help</span>: Show or hide this help document.</span></li>
</ul>

<h3>Where can I try the full prototype?</h3>

<p>
You can clone and work the full prototype, a standalone desktop app, by following instructions at this project's <a href="https://github.com/andrewhead/codescoop">source code repository</a>.
</p>

<h3>I have another question!</h3>

<p>
Get in touch with us by emailing andrewhead@berkeley.edu.
</p>

<p>
Get more details about the tool and the project in the <a href="https://codescoop.berkeley.edu/pdfs/example_extraction.pdf">paper</a> and on the <a href="https://codescoop.berkeley.edu">project</a> website.
</p>
"""

module.exports.HelpView = class HelpView extends $

  constructor: ->

    element = $ "<div></div>"
      .addClass "help"
      .html HELP_HTML

    @.extend @, element
