// @melloware/coloris@0.25.0 downloaded from https://ga.jspm.io/npm:@melloware/coloris@0.25.0/dist/esm/coloris.js

const e=(()=>((e,t,l,a)=>{const r=t.createElement("canvas").getContext("2d");const n={r:0,g:0,b:0,h:0,s:0,v:0,a:1};let o,s,c,i,u,f,p,d,h,b,y,m,g,v,w,k,E={};const L={el:"[data-coloris]",parent:"body",theme:"default",themeMode:"light",rtl:false,wrap:true,margin:2,format:"hex",formatToggle:false,swatches:[],swatchesOnly:false,alpha:true,forceAlpha:false,focusInput:true,selectInput:false,inline:false,defaultColor:"#000000",clearButton:false,clearLabel:"Clear",closeButton:false,closeLabel:"Close",onChange:()=>a,a11y:{open:"Open color picker",close:"Close color picker",clear:"Clear the selected color",marker:"Saturation: {s}. Brightness: {v}.",hueSlider:"Hue slider",alphaSlider:"Opacity slider",input:"Color value field",format:"Color format",swatch:"Color swatch",instruction:"Saturation and brightness selector. Use up, down, left and right arrow keys to select."}};const x={};let A="";let $={};let C=false;
/**
     * Configure the color picker.
     * @param {object} options Configuration options.
     */function S(l){if(typeof l==="object")for(const r in l)switch(r){case"el":I(l.el);l.wrap!==false&&D(l.el);break;case"parent":o=l.parent instanceof HTMLElement?l.parent:t.querySelector(l.parent);if(o){o.appendChild(s);L.parent=l.parent;o===t.body&&(o=a)}break;case"themeMode":L.themeMode=l.themeMode;l.themeMode==="auto"&&e.matchMedia&&e.matchMedia("(prefers-color-scheme: dark)").matches&&(L.themeMode="dark");case"theme":l.theme&&(L.theme=l.theme);s.className=`clr-picker clr-${L.theme} clr-${L.themeMode}`;L.inline&&O();break;case"rtl":L.rtl=!!l.rtl;Array.from(t.getElementsByClassName("clr-field")).forEach((e=>e.classList.toggle("clr-rtl",L.rtl)));break;case"margin":l.margin*=1;L.margin=isNaN(l.margin)?L.margin:l.margin;break;case"wrap":l.el&&l.wrap&&D(l.el);break;case"formatToggle":L.formatToggle=!!l.formatToggle;se("clr-format").style.display=L.formatToggle?"block":"none";L.formatToggle&&(L.format="auto");break;case"swatches":if(Array.isArray(l.swatches)){const e=se("clr-swatches");const a=t.createElement("div");e.textContent="";l.swatches.forEach(((e,l)=>{const r=t.createElement("button");r.setAttribute("type","button");r.setAttribute("id",`clr-swatch-${l}`);r.setAttribute("aria-labelledby",`clr-swatch-label clr-swatch-${l}`);r.style.color=e;r.textContent=e;a.appendChild(r)}));l.swatches.length&&e.appendChild(a);L.swatches=l.swatches.slice()}break;case"swatchesOnly":L.swatchesOnly=!!l.swatchesOnly;s.setAttribute("data-minimal",L.swatchesOnly);break;case"alpha":L.alpha=!!l.alpha;s.setAttribute("data-alpha",L.alpha);break;case"inline":L.inline=!!l.inline;s.setAttribute("data-inline",L.inline);if(L.inline){const e=l.defaultColor||L.defaultColor;v=Y(e);O();W(e)}break;case"clearButton":if(typeof l.clearButton==="object"){if(l.clearButton.label){L.clearLabel=l.clearButton.label;p.innerHTML=L.clearLabel}l.clearButton=l.clearButton.show}L.clearButton=!!l.clearButton;p.style.display=L.clearButton?"block":"none";break;case"clearLabel":L.clearLabel=l.clearLabel;p.innerHTML=L.clearLabel;break;case"closeButton":L.closeButton=!!l.closeButton;L.closeButton?s.insertBefore(d,u):u.appendChild(d);break;case"closeLabel":L.closeLabel=l.closeLabel;d.innerHTML=L.closeLabel;break;case"a11y":const n=l.a11y;let i=false;if(typeof n==="object")for(const e in n)if(n[e]&&L.a11y[e]){L.a11y[e]=n[e];i=true}if(i){const e=se("clr-open-label");const t=se("clr-swatch-label");e.innerHTML=L.a11y.open;t.innerHTML=L.a11y.swatch;d.setAttribute("aria-label",L.a11y.close);p.setAttribute("aria-label",L.a11y.clear);h.setAttribute("aria-label",L.a11y.hueSlider);y.setAttribute("aria-label",L.a11y.alphaSlider);f.setAttribute("aria-label",L.a11y.input);c.setAttribute("aria-label",L.a11y.instruction)}break;default:L[r]=l[r]}}
/**
     * Add or update a virtual instance.
     * @param {String} selector The CSS selector of the elements to which the instance is attached.
     * @param {Object} options Per-instance options to apply.
     */function T(e,t){if(typeof e==="string"&&typeof t==="object"){x[e]=t;C=true}}
/**
     * Remove a virtual instance.
     * @param {String} selector The CSS selector of the elements to which the instance is attached.
     */function B(e){delete x[e];if(Object.keys(x).length===0){C=false;e===A&&H()}}
/**
     * Attach a virtual instance to an element if it matches a selector.
     * @param {Object} element Target element that will receive a virtual instance if applicable.
     */function M(e){if(C){const t=["el","wrap","rtl","inline","defaultColor","a11y"];for(let l in x){const a=x[l];if(e.matches(l)){A=l;$={};t.forEach((e=>delete a[e]));for(let e in a)$[e]=Array.isArray(L[e])?L[e].slice():L[e];S(a);break}}}}function H(){if(Object.keys($).length>0){S($);A="";$={}}}
/**
     * Bind the color picker to input fields that match the selector.
     * @param {(string|HTMLElement|HTMLElement[])} selector A CSS selector string, a DOM element or a list of DOM elements.
     */function I(e){e instanceof HTMLElement&&(e=[e]);if(Array.isArray(e))e.forEach((e=>{ce(e,"click",N);ce(e,"input",P)}));else{ce(t,"click",e,N);ce(t,"input",e,P)}}
/**
     * Open the color picker.
     * @param {object} event The event that opens the color picker.
     */function N(e){if(!L.inline){M(e.target);g=e.target;w=g.value;v=Y(w);s.classList.add("clr-open");O();W(w);if(L.focusInput||L.selectInput){f.focus({preventScroll:true});f.setSelectionRange(g.selectionStart,g.selectionEnd)}L.selectInput&&f.select();(k||L.swatchesOnly)&&oe().shift().focus();g.dispatchEvent(new Event("open",{bubbles:false}))}}function O(){if(!s||!g&&!L.inline)return;const l=o;const a=e.scrollY;const r=s.offsetWidth;const n=s.offsetHeight;const i={left:false,top:false};let u,f,p;let d={x:0,y:0};if(l){u=e.getComputedStyle(l);f=parseFloat(u.marginTop);p=parseFloat(u.borderTopWidth);d=l.getBoundingClientRect();d.y+=p+a}if(!L.inline){const e=g.getBoundingClientRect();let o=e.x;let c=a+e.y+e.height+L.margin;if(l){o-=d.x;c-=d.y;if(o+r>l.clientWidth){o+=e.width-r;i.left=true}if(c+n>l.clientHeight-f&&n+L.margin<=e.top-(d.y-a)){c-=e.height+n+L.margin*2;i.top=true}c+=l.scrollTop}else{if(o+r>t.documentElement.clientWidth){o+=e.width-r;i.left=true}if(c+n-a>t.documentElement.clientHeight&&n+L.margin<=e.top){c=a+e.y-n-L.margin;i.top=true}}s.classList.toggle("clr-left",i.left);s.classList.toggle("clr-top",i.top);s.style.left=`${o}px`;s.style.top=`${c}px`;d.x+=s.offsetLeft;d.y+=s.offsetTop}E={width:c.offsetWidth,height:c.offsetHeight,x:c.offsetLeft+d.x,y:c.offsetTop+d.y}}
/**
     * Wrap the linked input fields in a div that adds a color preview.
     * @param {(string|HTMLElement|HTMLElement[])} selector A CSS selector string, a DOM element or a list of DOM elements.
     */function D(e){e instanceof HTMLElement?j(e):Array.isArray(e)?e.forEach(j):t.querySelectorAll(e).forEach(j)}
/**
       * Wrap an input field in a div that adds a color preview.
       * @param {object} field The input field.
       */function j(e){const l=e.parentNode;if(!l.classList.contains("clr-field")){const a=t.createElement("div");let r="clr-field";(L.rtl||e.classList.contains("clr-rtl"))&&(r+=" clr-rtl");a.innerHTML='<button type="button" aria-labelledby="clr-open-label"></button>';l.insertBefore(a,e);a.className=r;a.style.color=e.value;a.appendChild(e)}}
/**
     * Update the color preview of an input field
     * @param {object} event The "input" event that triggers the color change.
     */function P(e){const t=e.target.parentNode;t.classList.contains("clr-field")&&(t.style.color=e.target.value)}
/**
     * Close the color picker.
     * @param {boolean} [revert] If true, revert the color to the original value.
     */function R(e){if(g&&!L.inline){const t=g;if(e){g=a;if(w!==t.value){t.value=w;t.dispatchEvent(new Event("input",{bubbles:true}))}}setTimeout((()=>{w!==t.value&&t.dispatchEvent(new Event("change",{bubbles:true}))}));s.classList.remove("clr-open");C&&H();t.dispatchEvent(new Event("close",{bubbles:false}));L.focusInput&&t.focus({preventScroll:true});g=a}}
/**
     * Set the active color from a string.
     * @param {string} str String representing a color.
     */function W(e){const t=te(e);const l=ee(t);U(l.s,l.v);J(t,l);h.value=l.h;s.style.color=`hsl(${l.h}, 100%, 50%)`;b.style.left=l.h/360*100+"%";i.style.left=E.width*l.s/100+"px";i.style.top=E.height-E.height*l.v/100+"px";y.value=l.a*100;m.style.left=l.a*100+"%"}
/**
     * Guess the color format from a string.
     * @param {string} str String representing a color.
     * @return {string} The color format.
     */function Y(e){const t=e.substring(0,3).toLowerCase();return t==="rgb"||t==="hsl"?t:"hex"}
/**
     * Copy the active color to the linked input field.
     * @param {number} [color] Color value to override the active color.
     */function q(l){l=l!==a?l:f.value;if(g){g.value=l;g.dispatchEvent(new Event("input",{bubbles:true}))}L.onChange&&L.onChange.call(e,l,g);t.dispatchEvent(new CustomEvent("coloris:pick",{detail:{color:l,currentEl:g}}))}
/**
     * Set the active color based on a specific point in the color gradient.
     * @param {number} x Left position.
     * @param {number} y Top position.
     */function F(e,t){const l={h:h.value*1,s:e/E.width*100,v:100-t/E.height*100,a:y.value/100};const a=Z(l);U(l.s,l.v);J(a,l);q()}
/**
     * Update the color marker's accessibility label.
     * @param {number} saturation
     * @param {number} value
     */function U(e,t){let l=L.a11y.marker;e=e.toFixed(1)*1;t=t.toFixed(1)*1;l=l.replace("{s}",e);l=l.replace("{v}",t);i.setAttribute("aria-label",l)}
/**
     * Get the pageX and pageY positions of the pointer.
     * @param {object} event The MouseEvent or TouchEvent object.
     * @return {object} The pageX and pageY positions.
     */function X(e){return{pageX:e.changedTouches?e.changedTouches[0].pageX:e.pageX,pageY:e.changedTouches?e.changedTouches[0].pageY:e.pageY}}
/**
     * Move the color marker when dragged.
     * @param {object} event The MouseEvent object.
     */function z(e){const t=X(e);let l=t.pageX-E.x;let a=t.pageY-E.y;o&&(a+=o.scrollTop);K(l,a);e.preventDefault();e.stopPropagation()}
/**
     * Move the color marker when the arrow keys are pressed.
     * @param {number} offsetX The horizontal amount to move.
     * @param {number} offsetY The vertical amount to move.
     */function G(e,t){let l=i.style.left.replace("px","")*1+e;let a=i.style.top.replace("px","")*1+t;K(l,a)}
/**
     * Set the color marker's position.
     * @param {number} x Left position.
     * @param {number} y Top position.
     */function K(e,t){e=e<0?0:e>E.width?E.width:e;t=t<0?0:t>E.height?E.height:t;i.style.left=`${e}px`;i.style.top=`${t}px`;F(e,t);i.focus()}
/**
     * Update the color picker's input field and preview thumb.
     * @param {Object} rgba Red, green, blue and alpha values.
     * @param {Object} [hsva] Hue, saturation, value and alpha values.
     */function J(e,l){e===void 0&&(e={});l===void 0&&(l={});let a=L.format;for(const t in e)n[t]=e[t];for(const e in l)n[e]=l[e];const r=le(n);const o=r.substring(0,7);i.style.color=o;m.parentNode.style.color=o;m.style.color=r;u.style.color=r;c.style.display="none";c.offsetHeight;c.style.display="";m.nextElementSibling.style.display="none";m.nextElementSibling.offsetHeight;m.nextElementSibling.style.display="";a==="mixed"?a=n.a===1?"hex":"rgb":a==="auto"&&(a=v);switch(a){case"hex":f.value=r;break;case"rgb":f.value=ae(n);break;case"hsl":f.value=re(_(n));break}t.querySelector(`.clr-format [value="${a}"]`).checked=true}function Q(){const e=h.value*1;const t=i.style.left.replace("px","")*1;const l=i.style.top.replace("px","")*1;s.style.color=`hsl(${e}, 100%, 50%)`;b.style.left=e/360*100+"%";F(t,l)}function V(){const e=y.value/100;m.style.left=e*100+"%";J({a:e});q()}
/**
     * Convert HSVA to RGBA.
     * @param {object} hsva Hue, saturation, value and alpha values.
     * @return {object} Red, green, blue and alpha values.
     */function Z(e){const t=e.s/100;const a=e.v/100;let r=t*a;let n=e.h/60;let o=r*(1-l.abs(n%2-1));let s=a-r;r+=s;o+=s;const c=l.floor(n)%6;const i=[r,o,s,s,o,r][c];const u=[o,r,r,o,s,s][c];const f=[s,s,o,r,r,o][c];return{r:l.round(i*255),g:l.round(u*255),b:l.round(f*255),a:e.a}}
/**
     * Convert HSVA to HSLA.
     * @param {object} hsva Hue, saturation, value and alpha values.
     * @return {object} Hue, saturation, lightness and alpha values.
     */function _(e){const t=e.v/100;const a=t*(1-e.s/100/2);let r;a>0&&a<1&&(r=l.round((t-a)/l.min(a,1-a)*100));return{h:e.h,s:r||0,l:l.round(a*100),a:e.a}}
/**
     * Convert RGBA to HSVA.
     * @param {object} rgba Red, green, blue and alpha values.
     * @return {object} Hue, saturation, value and alpha values.
     */function ee(e){const t=e.r/255;const a=e.g/255;const r=e.b/255;const n=l.max(t,a,r);const o=l.min(t,a,r);const s=n-o;const c=n;let i=0;let u=0;if(s){n===t&&(i=(a-r)/s);n===a&&(i=2+(r-t)/s);n===r&&(i=4+(t-a)/s);n&&(u=s/n)}i=l.floor(i*60);return{h:i<0?i+360:i,s:l.round(u*100),v:l.round(c*100),a:e.a}}
/**
     * Parse a string to RGBA.
     * @param {string} str String representing a color.
     * @return {object} Red, green, blue and alpha values.
     */function te(e){const t=/^((rgba)|rgb)[\D]+([\d.]+)[\D]+([\d.]+)[\D]+([\d.]+)[\D]*?([\d.]+|$)/i;let l,a;r.fillStyle="#000";r.fillStyle=e;l=t.exec(r.fillStyle);if(l)a={r:l[3]*1,g:l[4]*1,b:l[5]*1,a:l[6]*1};else{l=r.fillStyle.replace("#","").match(/.{2}/g).map((e=>parseInt(e,16)));a={r:l[0],g:l[1],b:l[2],a:1}}return a}
/**
     * Convert RGBA to Hex.
     * @param {object} rgba Red, green, blue and alpha values.
     * @return {string} Hex color string.
     */function le(e){let t=e.r.toString(16);let l=e.g.toString(16);let a=e.b.toString(16);let r="";e.r<16&&(t="0"+t);e.g<16&&(l="0"+l);e.b<16&&(a="0"+a);if(L.alpha&&(e.a<1||L.forceAlpha)){const t=e.a*255|0;r=t.toString(16);t<16&&(r="0"+r)}return"#"+t+l+a+r}
/**
     * Convert RGBA values to a CSS rgb/rgba string.
     * @param {object} rgba Red, green, blue and alpha values.
     * @return {string} CSS color string.
     */function ae(e){return!L.alpha||e.a===1&&!L.forceAlpha?`rgb(${e.r}, ${e.g}, ${e.b})`:`rgba(${e.r}, ${e.g}, ${e.b}, ${e.a})`}
/**
     * Convert HSLA values to a CSS hsl/hsla string.
     * @param {object} hsla Hue, saturation, lightness and alpha values.
     * @return {string} CSS color string.
     */function re(e){return!L.alpha||e.a===1&&!L.forceAlpha?`hsl(${e.h}, ${e.s}%, ${e.l}%)`:`hsla(${e.h}, ${e.s}%, ${e.l}%, ${e.a})`}function ne(){if(!t.getElementById("clr-picker")){o=a;s=t.createElement("div");s.setAttribute("id","clr-picker");s.className="clr-picker";s.innerHTML=`<input id="clr-color-value" name="clr-color-value" class="clr-color" type="text" value="" spellcheck="false" aria-label="${L.a11y.input}"><div id="clr-color-area" class="clr-gradient" role="application" aria-label="${L.a11y.instruction}"><div id="clr-color-marker" class="clr-marker" tabindex="0"></div></div><div class="clr-hue"><input id="clr-hue-slider" name="clr-hue-slider" type="range" min="0" max="360" step="1" aria-label="${L.a11y.hueSlider}"><div id="clr-hue-marker"></div></div><div class="clr-alpha"><input id="clr-alpha-slider" name="clr-alpha-slider" type="range" min="0" max="100" step="1" aria-label="${L.a11y.alphaSlider}"><div id="clr-alpha-marker"></div><span></span></div><div id="clr-format" class="clr-format"><fieldset class="clr-segmented"><legend>${L.a11y.format}</legend><input id="clr-f1" type="radio" name="clr-format" value="hex"><label for="clr-f1">Hex</label><input id="clr-f2" type="radio" name="clr-format" value="rgb"><label for="clr-f2">RGB</label><input id="clr-f3" type="radio" name="clr-format" value="hsl"><label for="clr-f3">HSL</label><span></span></fieldset></div><div id="clr-swatches" class="clr-swatches"></div><button type="button" id="clr-clear" class="clr-clear" aria-label="${L.a11y.clear}">${L.clearLabel}</button><div id="clr-color-preview" class="clr-preview"><button type="button" id="clr-close" class="clr-close" aria-label="${L.a11y.close}">${L.closeLabel}</button></div><span id="clr-open-label" hidden>${L.a11y.open}</span><span id="clr-swatch-label" hidden>${L.a11y.swatch}</span>`;t.body.appendChild(s);c=se("clr-color-area");i=se("clr-color-marker");p=se("clr-clear");d=se("clr-close");u=se("clr-color-preview");f=se("clr-color-value");h=se("clr-hue-slider");b=se("clr-hue-marker");y=se("clr-alpha-slider");m=se("clr-alpha-marker");I(L.el);D(L.el);ce(s,"mousedown",(e=>{s.classList.remove("clr-keyboard-nav");e.stopPropagation()}));ce(c,"mousedown",(e=>{ce(t,"mousemove",z)}));ce(c,"contextmenu",(e=>{e.preventDefault()}));ce(c,"touchstart",(e=>{t.addEventListener("touchmove",z,{passive:false})}));ce(i,"mousedown",(e=>{ce(t,"mousemove",z)}));ce(i,"touchstart",(e=>{t.addEventListener("touchmove",z,{passive:false})}));ce(f,"change",(e=>{const t=f.value;if(g||L.inline){const e=t===""?t:W(t);q(e)}}));ce(p,"click",(e=>{q("");R()}));ce(d,"click",(e=>{q();R()}));ce(se("clr-format"),"click",".clr-format input",(e=>{v=e.target.value;J();q()}));ce(s,"click",".clr-swatches button",(e=>{W(e.target.textContent);q();L.swatchesOnly&&R()}));ce(t,"mouseup",(e=>{t.removeEventListener("mousemove",z)}));ce(t,"touchend",(e=>{t.removeEventListener("touchmove",z)}));ce(t,"mousedown",(e=>{k=false;s.classList.remove("clr-keyboard-nav");R()}));ce(t,"keydown",(e=>{const t=e.key;const l=e.target;const a=e.shiftKey;const r=["Tab","ArrowUp","ArrowDown","ArrowLeft","ArrowRight"];if(t!=="Escape")if(t!=="Enter"||l.tagName==="BUTTON"){if(r.includes(t)){k=true;s.classList.add("clr-keyboard-nav")}if(t==="Tab"&&l.matches(".clr-picker *")){const t=oe();const r=t.shift();const n=t.pop();if(a&&l===r){n.focus();e.preventDefault()}else if(!a&&l===n){r.focus();e.preventDefault()}}}else R();else R(true)}));ce(t,"click",".clr-field button",(e=>{C&&H();e.target.nextElementSibling.dispatchEvent(new Event("click",{bubbles:true}))}));ce(i,"keydown",(e=>{const t={ArrowUp:[0,-1],ArrowDown:[0,1],ArrowLeft:[-1,0],ArrowRight:[1,0]};if(Object.keys(t).includes(e.key)){G(...t[e.key]);e.preventDefault()}}));ce(c,"click",z);ce(h,"input",Q);ce(y,"input",V)}}function oe(){const e=Array.from(s.querySelectorAll("input, button"));const t=e.filter((e=>!!e.offsetWidth));return t}
/**
     * Shortcut for getElementById to optimize the minified JS.
     * @param {string} id The element id.
     * @return {object} The DOM element with the provided id.
     */function se(e){return t.getElementById(e)}
/**
     * Shortcut for addEventListener to optimize the minified JS.
     * @param {object} context The context to which the listener is attached.
     * @param {string} type Event type.
     * @param {(string|function)} selector Event target if delegation is used, event handler if not.
     * @param {function} [fn] Event handler if delegation is used.
     */function ce(e,t,l,a){const r=Element.prototype.matches||Element.prototype.msMatchesSelector;if(typeof l==="string")e.addEventListener(t,(e=>{r.call(e.target,l)&&a.call(e.target,e)}));else{a=l;e.addEventListener(t,a)}}
/**
     * Call a function only when the DOM is ready.
     * @param {function} fn The function to call.
     * @param {array} [args] Arguments to pass to the function.
     */function ie(e,l){l=l!==a?l:[];t.readyState!=="loading"?e(...l):t.addEventListener("DOMContentLoaded",(()=>{e(...l)}))}NodeList!==a&&NodeList.prototype&&!NodeList.prototype.forEach&&(NodeList.prototype.forEach=Array.prototype.forEach);
/**
     * Copy the active color to the linked input field and set the color.
     * @param {string} [color] Color value to override the active color.
     * @param {HTMLelement} [target] the element setting the color on
     */function ue(e,t){g=t;w=g.value;M(t);v=Y(e);O();W(e);q();w!==e&&g.dispatchEvent(new Event("change",{bubbles:true}))}const fe=(()=>{const t={init:ne,set:S,wrap:D,close:R,setInstance:T,setColor:ue,removeInstance:B,updatePosition:O,ready:ie};function l(e){ie((()=>{e&&(typeof e==="string"?I(e):S(e))}))}for(const e in t)l[e]=function(){for(var l=arguments.length,a=new Array(l),r=0;r<l;r++)a[r]=arguments[r];ie(t[e],a)};ie((()=>{e.addEventListener("resize",(e=>{l.updatePosition()}));e.addEventListener("scroll",(e=>{l.updatePosition()}))}));return l})();fe.coloris=fe;return fe})(window,document,Math))();const t=e.coloris;const l=e.init;const a=e.set;const r=e.wrap;const n=e.close;const o=e.setInstance;const s=e.removeInstance;const c=e.updatePosition;export{n as close,t as coloris,e as default,l as init,s as removeInstance,a as set,o as setInstance,c as updatePosition,r as wrap};

