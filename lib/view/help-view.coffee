$ = require "jquery"

HELP_HTML = """
<h1>CodeScoop Demo</h1>

<p>
In this demo, you can try the tool described in the paper
<span class="paper_name">
<a href="https://codescoop.berkeley.edu/files/ExampleExtraction.pdf">Interactive
Extraction of Examples from Existing Code</a></span>.
</p>

<h2>Step 1. What am I looking at?</h2>

<p>The code to the left is a program that fetches data from a database.</p>

<p>By following these instructions, you can use CodeScoop, our prototype tool, to pull a shorter, executable example from this source program.</p>

<h2>Step 2. Extract a line.</h2>

<p>
Start extracting an example from the source program:
<ol>
  <li>Select some text (for example, line 49).</li>
  <li>Click the "Scoop" <span class="icon icon-paintcan"></span>button</li>
</ol>
</p>

<p>
Your selections will be wrapped in a new code file, which will be used for building the example.
</p>

<h2>Step 3. Flesh out the example.</h2>

<p>
Add code to the example by:
<ol class="long-bullets">
  <li><span class="action_name">Resolving issues</span>: Fix <span class="broken_symbols">broken symbols</span> by clicking those symbols, and following prompts to add code or insert literals.</li>
  <li><span class="action_name">Adding other lines</span>: Add any other line by clicking line numbers in the source program editor.</li>
</ol>
</p>

<h2>Step 4. What else can I do?</h2>

<p>
Get an overview of CodeScoop's functionality in this 1-minute video:
</p>

<div class="video-container">
  <iframe class="video" src="https://www.youtube.com/embed/RYbhnRDbvyY?start=60&vq=hd1080" frameborder="0" allow="encrypted-media" allowfullscreen></iframe>
</div>

<p>
Still curious?  Check out the paper's <a href="https://www.youtube.com?v=RYbhnRDbvyY&start=60&vq=hd1080">video figure</a>, or read <a href="https://codescoop.berkeley.edu/files/ExampleExtraction.pdf">the paper</a>.
</p>

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
You can run the full prototype—a standalone desktop app—by following instructions in the project's <a href="https://github.com/andrewhead/codescoop">source code repository</a>.
</p>

<h3>I have another question!</h3>

<p>
Get in touch with us by emailing andrewhead@berkeley.edu.
</p>

<p>
Get more details about the tool and the project in the <a href="https://codescoop.berkeley.edu/files/ExampleExtraction.pdf">paper</a> and on the <a href="https://codescoop.berkeley.edu/info">project website</a>.
</p>
"""

module.exports.HelpView = class HelpView extends $

  constructor: ->

    element = $ "<div></div>"
      .addClass "help"
      .html HELP_HTML

    @.extend @, element
