const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./assets/dashboard-BQftqJZE.js","./assets/index-kJ3bsOU1.js","./assets/pm-Dj_62FpQ.js","./assets/dataflows-Dr2Ef8bh.js","./assets/tasks-CxgCqZXy.js","./assets/changelog-kS_NZw1C.js","./assets/logger-Cq9hvQPy.js","./assets/knowledge-iW30SVUZ.js","./assets/utils-CSjTgnrH.js","./assets/workflow-BnPrisCC.js","./assets/sessions-BrMpENKd.js","./assets/PageHeader.vue_vue_type_script_setup_true_lang-x-0LZxLa.js","./assets/session-detail-BgaJxj_x.js","./assets/MarkdownContent-DyBNkW15.js","./assets/DetailPanel.vue_vue_type_script_setup_true_lang-B115sO7W.js","./assets/JsonBlock.vue_vue_type_script_setup_true_lang-D4lkhHol.js","./assets/agents-ByacHkKz.js","./assets/EntryDetailPanel-Bg-7l0js.js","./assets/models-BGLayZfU.js","./assets/tools-page-CAPkcnkU.js","./assets/traits-BCdYpwJm.js","./assets/endpoints-Va7stiZG.js","./assets/policies-C7MNLQNg.js","./assets/structure-BoeDRm0U.js","./assets/dataflow-detail-BZVhBmyi.js","./assets/plugin-page-78CA4jh7.js","./assets/PluginHost-DUK2xtKt.js","./assets/logger-CJ4vPYnn.js","./assets/activity-BTPuvvNP.js","./assets/system-Ba_7tip8.js","./assets/tests-C21pmcDl.js","./assets/settings-86u394KL.js","./assets/settings-environment-DV741d7r.js","./assets/settings-registry-CUu_UwsG.js","./assets/settings-hub-VxWUSLw0.js","./assets/HubInstallWarnings.vue_vue_type_script_setup_true_lang-DYkwg4wg.js","./assets/settings-hub-module-R7tsGer5.js","./assets/knowledge-B7f2toOe.js","./assets/components-C4F7M12i.js","./assets/tasks-C61-GdIs.js","./assets/task-detail-CkwwjE7P.js","./assets/changes-DTloMyYz.js"])))=>i.map(i=>d[i]);
import{Icon as K,addCollection as yo}from"@iconify/vue";import{createPinia as So}from"pinia";import{ref as M,readonly as _o,getCurrentInstance as ln,onMounted as Vn,nextTick as wo,watch as Re,reactive as $o,useId as ko,mergeProps as X,openBlock as O,createElementBlock as L,createElementVNode as W,renderSlot as Fe,createTextVNode as Xe,toDisplayString as ee,resolveComponent as zt,resolveDirective as Po,withDirectives as xo,createBlock as Me,resolveDynamicComponent as Oo,withCtx as Be,createCommentVNode as F,normalizeClass as Ce,inject as Tt,defineComponent as Le,createVNode as I,unref as A,Fragment as et,renderList as tt,Teleport as To,withModifiers as Co,withKeys as un,normalizeStyle as Ht,computed as q,onUnmounted as Ao,h as Ge,createApp as Eo}from"vue";import{useRouter as Mn,useRoute as Lo,createMemoryHistory as No,createRouter as jo,RouterLink as Io}from"vue-router";import{host as Pt,on as Do,setLocalRouter as Ro}from"@wippy-fe/proxy";(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))o(r);new MutationObserver(r=>{for(const a of r)if(a.type==="childList")for(const s of a.addedNodes)s.tagName==="LINK"&&s.rel==="modulepreload"&&o(s)}).observe(document,{childList:!0,subtree:!0});function n(r){const a={};return r.integrity&&(a.integrity=r.integrity),r.referrerPolicy&&(a.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?a.credentials="include":r.crossOrigin==="anonymous"?a.credentials="omit":a.credentials="same-origin",a}function o(r){if(r.ep)return;r.ep=!0;const a=n(r);fetch(r.href,a)}})();var Vo=Object.defineProperty,dn=Object.getOwnPropertySymbols,Mo=Object.prototype.hasOwnProperty,Bo=Object.prototype.propertyIsEnumerable,cn=(e,t,n)=>t in e?Vo(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,Wo=(e,t)=>{for(var n in t||(t={}))Mo.call(t,n)&&cn(e,n,t[n]);if(dn)for(var n of dn(t))Bo.call(t,n)&&cn(e,n,t[n]);return e};function Ne(e){return e==null||e===""||Array.isArray(e)&&e.length===0||!(e instanceof Date)&&typeof e=="object"&&Object.keys(e).length===0}function qt(e,t,n=new WeakSet){if(e===t)return!0;if(!e||!t||typeof e!="object"||typeof t!="object"||n.has(e)||n.has(t))return!1;n.add(e).add(t);let o=Array.isArray(e),r=Array.isArray(t),a,s,l;if(o&&r){if(s=e.length,s!=t.length)return!1;for(a=s;a--!==0;)if(!qt(e[a],t[a],n))return!1;return!0}if(o!=r)return!1;let i=e instanceof Date,u=t instanceof Date;if(i!=u)return!1;if(i&&u)return e.getTime()==t.getTime();let d=e instanceof RegExp,c=t instanceof RegExp;if(d!=c)return!1;if(d&&c)return e.toString()==t.toString();let p=Object.keys(e);if(s=p.length,s!==Object.keys(t).length)return!1;for(a=s;a--!==0;)if(!Object.prototype.hasOwnProperty.call(t,p[a]))return!1;for(a=s;a--!==0;)if(l=p[a],!qt(e[l],t[l],n))return!1;return!0}function Uo(e,t){return qt(e,t)}function Ct(e){return typeof e=="function"&&"call"in e&&"apply"in e}function D(e){return!Ne(e)}function pn(e,t){if(!e||!t)return null;try{let n=e[t];if(D(n))return n}catch{}if(Object.keys(e).length){if(Ct(t))return t(e);if(t.indexOf(".")===-1)return e[t];{let n=t.split("."),o=e;for(let r=0,a=n.length;r<a;++r){if(o==null)return null;o=o[n[r]]}return o}}return null}function Zi(e,t,n){return n?pn(e,n)===pn(t,n):Uo(e,t)}function he(e,t=!0){return e instanceof Object&&e.constructor===Object&&(t||Object.keys(e).length!==0)}function Bn(e={},t={}){let n=Wo({},e);return Object.keys(t).forEach(o=>{let r=o;he(t[r])&&r in e&&he(e[r])?n[r]=Bn(e[r],t[r]):n[r]=t[r]}),n}function zo(...e){return e.reduce((t,n,o)=>o===0?n:Bn(t,n),{})}function Ji(e,t){let n=-1;if(D(e))try{n=e.findLastIndex(t)}catch{n=e.lastIndexOf([...e].reverse().find(t))}return n}function ie(e,...t){return Ct(e)?e(...t):e}function te(e,t=!0){return typeof e=="string"&&(t||e!=="")}function ge(e){return te(e)?e.replace(/(-|_)/g,"").toLowerCase():e}function tn(e,t="",n={}){let o=ge(t).split("."),r=o.shift();if(r){if(he(e)){let a=Object.keys(e).find(s=>ge(s)===r)||"";return tn(ie(e[a],n),o.join("."),n)}return}return ie(e,n)}function Wn(e,t=!0){return Array.isArray(e)&&(t||e.length!==0)}function Ho(e){return D(e)&&!isNaN(e)}function Ae(e,t){if(t){let n=t.test(e);return t.lastIndex=0,n}return!1}function qo(...e){return zo(...e)}function Qe(e){return e&&e.replace(/\/\*(?:(?!\*\/)[\s\S])*\*\/|[\r\n\t]+/g,"").replace(/ {2,}/g," ").replace(/ ([{:}]) /g,"$1").replace(/([;,]) /g,"$1").replace(/ !/g,"!").replace(/: /g,":").trim()}function Ko(e){return te(e,!1)?e[0].toUpperCase()+e.slice(1):e}function Un(e){return te(e)?e.replace(/(_)/g,"-").replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase():e}function zn(){let e=new Map;return{on(t,n){let o=e.get(t);return o?o.push(n):o=[n],e.set(t,o),this},off(t,n){let o=e.get(t);return o&&o.splice(o.indexOf(n)>>>0,1),this},emit(t,n){let o=e.get(t);o&&o.forEach(r=>{r(n)})},clear(){e.clear()}}}function Ze(...e){if(e){let t=[];for(let n=0;n<e.length;n++){let o=e[n];if(!o)continue;let r=typeof o;if(r==="string"||r==="number")t.push(o);else if(r==="object"){let a=Array.isArray(o)?[Ze(...o)]:Object.entries(o).map(([s,l])=>l?s:void 0);t=a.length?t.concat(a.filter(s=>!!s)):t}}return t.join(" ").trim()}}function Fo(e,t){return e?e.classList?e.classList.contains(t):new RegExp("(^| )"+t+"( |$)","gi").test(e.className):!1}function Kt(e,t){if(e&&t){let n=o=>{Fo(e,o)||(e.classList?e.classList.add(o):e.className+=" "+o)};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Go(){return window.innerWidth-document.documentElement.offsetWidth}function Xi(e){typeof e=="string"?Kt(document.body,e||"p-overflow-hidden"):(e!=null&&e.variableName&&document.body.style.setProperty(e.variableName,Go()+"px"),Kt(document.body,e?.className||"p-overflow-hidden"))}function Je(e,t){if(e&&t){let n=o=>{e.classList?e.classList.remove(o):e.className=e.className.replace(new RegExp("(^|\\b)"+o.split(" ").join("|")+"(\\b|$)","gi")," ")};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function es(e){typeof e=="string"?Je(document.body,e||"p-overflow-hidden"):(e!=null&&e.variableName&&document.body.style.removeProperty(e.variableName),Je(document.body,e?.className||"p-overflow-hidden"))}function Ft(e){for(let t of document?.styleSheets)try{for(let n of t?.cssRules)for(let o of n?.style)if(e.test(o))return{name:o,value:n.style.getPropertyValue(o).trim()}}catch{}return null}function Hn(e){let t={width:0,height:0};if(e){let[n,o]=[e.style.visibility,e.style.display],r=e.getBoundingClientRect();e.style.visibility="hidden",e.style.display="block",t.width=r.width||e.offsetWidth,t.height=r.height||e.offsetHeight,e.style.display=o,e.style.visibility=n}return t}function qn(){let e=window,t=document,n=t.documentElement,o=t.getElementsByTagName("body")[0],r=e.innerWidth||n.clientWidth||o.clientWidth,a=e.innerHeight||n.clientHeight||o.clientHeight;return{width:r,height:a}}function Gt(e){return e?Math.abs(e.scrollLeft):0}function Yo(){let e=document.documentElement;return(window.pageXOffset||Gt(e))-(e.clientLeft||0)}function Qo(){let e=document.documentElement;return(window.pageYOffset||e.scrollTop)-(e.clientTop||0)}function Zo(e){return e?getComputedStyle(e).direction==="rtl":!1}function ts(e,t,n=!0){var o,r,a,s;if(e){let l=e.offsetParent?{width:e.offsetWidth,height:e.offsetHeight}:Hn(e),i=l.height,u=l.width,d=t.offsetHeight,c=t.offsetWidth,p=t.getBoundingClientRect(),m=Qo(),f=Yo(),y=qn(),g,S,$="top";p.top+d+i>y.height?(g=p.top+m-i,$="bottom",g<0&&(g=m)):g=d+p.top+m,p.left+u>y.width?S=Math.max(0,p.left+f+c-u):S=p.left+f,Zo(e)?e.style.insetInlineEnd=S+"px":e.style.insetInlineStart=S+"px",e.style.top=g+"px",e.style.transformOrigin=$,n&&(e.style.marginTop=$==="bottom"?`calc(${(r=(o=Ft(/-anchor-gutter$/))==null?void 0:o.value)!=null?r:"2px"} * -1)`:(s=(a=Ft(/-anchor-gutter$/))==null?void 0:a.value)!=null?s:"")}}function ns(e,t){e&&(typeof t=="string"?e.style.cssText=t:Object.entries(t||{}).forEach(([n,o])=>e.style[n]=o))}function Jo(e,t){return e instanceof HTMLElement?e.offsetWidth:0}function os(e,t,n=!0,o=void 0){var r;if(e){let a=e.offsetParent?{width:e.offsetWidth,height:e.offsetHeight}:Hn(e),s=t.offsetHeight,l=t.getBoundingClientRect(),i=qn(),u,d,c=o??"top";if(!o&&l.top+s+a.height>i.height?(u=-1*a.height,c="bottom",l.top+u<0&&(u=-1*l.top)):u=s,a.width>i.width?d=l.left*-1:l.left+a.width>i.width?d=(l.left+a.width-i.width)*-1:d=0,e.style.top=u+"px",e.style.insetInlineStart=d+"px",e.style.transformOrigin=c,n){let p=(r=Ft(/-anchor-gutter$/))==null?void 0:r.value;e.style.marginTop=c==="bottom"?`calc(${p??"2px"} * -1)`:p??""}}}function Kn(e){if(e){let t=e.parentNode;return t&&t instanceof ShadowRoot&&t.host&&(t=t.host),t}return null}function Xo(e){return!!(e!==null&&typeof e<"u"&&e.nodeName&&Kn(e))}function je(e){return typeof Element<"u"?e instanceof Element:e!==null&&typeof e=="object"&&e.nodeType===1&&typeof e.nodeName=="string"}function xt(e,t={}){if(je(e)){let n=(o,r)=>{var a,s;let l=(a=e?.$attrs)!=null&&a[o]?[(s=e?.$attrs)==null?void 0:s[o]]:[];return[r].flat().reduce((i,u)=>{if(u!=null){let d=typeof u;if(d==="string"||d==="number")i.push(u);else if(d==="object"){let c=Array.isArray(u)?n(o,u):Object.entries(u).map(([p,m])=>o==="style"&&(m||m===0)?`${p.replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()}:${m}`:m?p:void 0);i=c.length?i.concat(c.filter(p=>!!p)):i}}return i},l)};Object.entries(t).forEach(([o,r])=>{if(r!=null){let a=o.match(/^on(.+)/);a?e.addEventListener(a[1].toLowerCase(),r):o==="p-bind"||o==="pBind"?xt(e,r):(r=o==="class"?[...new Set(n("class",r))].join(" ").trim():o==="style"?n("style",r).join(";").trim():r,(e.$attrs=e.$attrs||{})&&(e.$attrs[o]=r),e.setAttribute(o,r))}})}}function er(e,t={},...n){{let o=document.createElement(e);return xt(o,t),o.append(...n),o}}function tr(e,t){return je(e)?Array.from(e.querySelectorAll(t)):[]}function Fn(e,t){return je(e)?e.matches(t)?e:e.querySelector(t):null}function rs(e,t){e&&document.activeElement!==e&&e.focus(t)}function nr(e,t){if(je(e)){let n=e.getAttribute(t);return isNaN(n)?n==="true"||n==="false"?n==="true":n:+n}}function Gn(e,t=""){let n=tr(e,`button:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [href]:not([tabindex = "-1"]):not([style*="display:none"]):not([hidden])${t},
            input:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            select:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            textarea:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [tabIndex]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [contenteditable]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t}`),o=[];for(let r of n)getComputedStyle(r).display!="none"&&getComputedStyle(r).visibility!="hidden"&&o.push(r);return o}function as(e,t){let n=Gn(e,t);return n.length>0?n[0]:null}function mn(e){if(e){let t=e.offsetHeight,n=getComputedStyle(e);return t-=parseFloat(n.paddingTop)+parseFloat(n.paddingBottom)+parseFloat(n.borderTopWidth)+parseFloat(n.borderBottomWidth),t}return 0}function is(e,t){let n=Gn(e,t);return n.length>0?n[n.length-1]:null}function or(e){if(e){let t=e.getBoundingClientRect();return{top:t.top+(window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0),left:t.left+(window.pageXOffset||Gt(document.documentElement)||Gt(document.body)||0)}}return{top:"auto",left:"auto"}}function rr(e,t){return e?e.offsetHeight:0}function Yn(e,t=[]){let n=Kn(e);return n===null?t:Yn(n,t.concat([n]))}function ss(e){let t=[];if(e){let n=Yn(e),o=/(auto|scroll)/,r=a=>{try{let s=window.getComputedStyle(a,null);return o.test(s.getPropertyValue("overflow"))||o.test(s.getPropertyValue("overflowX"))||o.test(s.getPropertyValue("overflowY"))}catch{return!1}};for(let a of n){let s=a.nodeType===1&&a.dataset.scrollselectors;if(s){let l=s.split(",");for(let i of l){let u=Fn(a,i);u&&r(u)&&t.push(u)}}a.nodeType!==9&&r(a)&&t.push(a)}}return t}function fn(e){if(e){let t=e.offsetWidth,n=getComputedStyle(e);return t-=parseFloat(n.paddingLeft)+parseFloat(n.paddingRight)+parseFloat(n.borderLeftWidth)+parseFloat(n.borderRightWidth),t}return 0}function ar(){return!!(typeof window<"u"&&window.document&&window.document.createElement)}function ls(e,t=""){return je(e)?e.matches(`button:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [href][clientHeight][clientWidth]:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            input:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            select:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            textarea:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [tabIndex]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [contenteditable]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t}`):!1}function us(e){return!!(e&&e.offsetParent!=null)}function ds(){return"ontouchstart"in window||navigator.maxTouchPoints>0||navigator.msMaxTouchPoints>0}function ir(e,t="",n){je(e)&&n!==null&&n!==void 0&&e.setAttribute(t,n)}var yt={};function sr(e="pui_id_"){return Object.hasOwn(yt,e)||(yt[e]=0),yt[e]++,`${e}${yt[e]}`}var lr=Object.defineProperty,ur=Object.defineProperties,dr=Object.getOwnPropertyDescriptors,Ot=Object.getOwnPropertySymbols,Qn=Object.prototype.hasOwnProperty,Zn=Object.prototype.propertyIsEnumerable,bn=(e,t,n)=>t in e?lr(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,fe=(e,t)=>{for(var n in t||(t={}))Qn.call(t,n)&&bn(e,n,t[n]);if(Ot)for(var n of Ot(t))Zn.call(t,n)&&bn(e,n,t[n]);return e},Mt=(e,t)=>ur(e,dr(t)),Se=(e,t)=>{var n={};for(var o in e)Qn.call(e,o)&&t.indexOf(o)<0&&(n[o]=e[o]);if(e!=null&&Ot)for(var o of Ot(e))t.indexOf(o)<0&&Zn.call(e,o)&&(n[o]=e[o]);return n},cr=zn(),z=cr,nt=/{([^}]*)}/g,Jn=/(\d+\s+[\+\-\*\/]\s+\d+)/g,Xn=/var\([^)]+\)/g;function vn(e){return te(e)?e.replace(/[A-Z]/g,(t,n)=>n===0?t:"."+t.toLowerCase()).toLowerCase():e}function pr(e){return he(e)&&e.hasOwnProperty("$value")&&e.hasOwnProperty("$type")?e.$value:e}function mr(e){return e.replaceAll(/ /g,"").replace(/[^\w]/g,"-")}function Yt(e="",t=""){return mr(`${te(e,!1)&&te(t,!1)?`${e}-`:e}${t}`)}function eo(e="",t=""){return`--${Yt(e,t)}`}function fr(e=""){let t=(e.match(/{/g)||[]).length,n=(e.match(/}/g)||[]).length;return(t+n)%2!==0}function to(e,t="",n="",o=[],r){if(te(e)){let a=e.trim();if(fr(a))return;if(Ae(a,nt)){let s=a.replaceAll(nt,l=>{let i=l.replace(/{|}/g,"").split(".").filter(u=>!o.some(d=>Ae(u,d)));return`var(${eo(n,Un(i.join("-")))}${D(r)?`, ${r}`:""})`});return Ae(s.replace(Xn,"0"),Jn)?`calc(${s})`:s}return a}else if(Ho(e))return e}function br(e,t,n){te(t,!1)&&e.push(`${t}:${n};`)}function De(e,t){return e?`${e}{${t}}`:""}function no(e,t){if(e.indexOf("dt(")===-1)return e;function n(s,l){let i=[],u=0,d="",c=null,p=0;for(;u<=s.length;){let m=s[u];if((m==='"'||m==="'"||m==="`")&&s[u-1]!=="\\"&&(c=c===m?null:m),!c&&(m==="("&&p++,m===")"&&p--,(m===","||u===s.length)&&p===0)){let f=d.trim();f.startsWith("dt(")?i.push(no(f,l)):i.push(o(f)),d="",u++;continue}m!==void 0&&(d+=m),u++}return i}function o(s){let l=s[0];if((l==='"'||l==="'"||l==="`")&&s[s.length-1]===l)return s.slice(1,-1);let i=Number(s);return isNaN(i)?s:i}let r=[],a=[];for(let s=0;s<e.length;s++)if(e[s]==="d"&&e.slice(s,s+3)==="dt(")a.push(s),s+=2;else if(e[s]===")"&&a.length>0){let l=a.pop();a.length===0&&r.push([l,s])}if(!r.length)return e;for(let s=r.length-1;s>=0;s--){let[l,i]=r[s],u=e.slice(l+3,i),d=n(u,t),c=t(...d);e=e.slice(0,l)+c+e.slice(i+1)}return e}var cs=e=>{var t;let n=N.getTheme(),o=Qt(n,e,void 0,"variable"),r=(t=o?.match(/--[\w-]+/g))==null?void 0:t[0],a=Qt(n,e,void 0,"value");return{name:r,variable:o,value:a}},Ee=(...e)=>Qt(N.getTheme(),...e),Qt=(e={},t,n,o)=>{if(t){let{variable:r,options:a}=N.defaults||{},{prefix:s,transform:l}=e?.options||a||{},i=Ae(t,nt)?t:`{${t}}`;return o==="value"||Ne(o)&&l==="strict"?N.getTokenValue(t):to(i,void 0,s,[r.excludedKeyRegex],n)}return""};function St(e,...t){if(e instanceof Array){let n=e.reduce((o,r,a)=>{var s;return o+r+((s=ie(t[a],{dt:Ee}))!=null?s:"")},"");return no(n,Ee)}return ie(e,{dt:Ee})}function vr(e,t={}){let n=N.defaults.variable,{prefix:o=n.prefix,selector:r=n.selector,excludedKeyRegex:a=n.excludedKeyRegex}=t,s=[],l=[],i=[{node:e,path:o}];for(;i.length;){let{node:d,path:c}=i.pop();for(let p in d){let m=d[p],f=pr(m),y=Ae(p,a)?Yt(c):Yt(c,Un(p));if(he(f))i.push({node:f,path:y});else{let g=eo(y),S=to(f,y,o,[a]);br(l,g,S);let $=y;o&&$.startsWith(o+"-")&&($=$.slice(o.length+1)),s.push($.replace(/-/g,"."))}}}let u=l.join("");return{value:l,tokens:s,declarations:u,css:De(r,u)}}var me={regex:{rules:{class:{pattern:/^\.([a-zA-Z][\w-]*)$/,resolve(e){return{type:"class",selector:e,matched:this.pattern.test(e.trim())}}},attr:{pattern:/^\[(.*)\]$/,resolve(e){return{type:"attr",selector:`:root${e},:host${e}`,matched:this.pattern.test(e.trim())}}},media:{pattern:/^@media (.*)$/,resolve(e){return{type:"media",selector:e,matched:this.pattern.test(e.trim())}}},system:{pattern:/^system$/,resolve(e){return{type:"system",selector:"@media (prefers-color-scheme: dark)",matched:this.pattern.test(e.trim())}}},custom:{resolve(e){return{type:"custom",selector:e,matched:!0}}}},resolve(e){let t=Object.keys(this.rules).filter(n=>n!=="custom").map(n=>this.rules[n]);return[e].flat().map(n=>{var o;return(o=t.map(r=>r.resolve(n)).find(r=>r.matched))!=null?o:this.rules.custom.resolve(n)})}},_toVariables(e,t){return vr(e,{prefix:t?.prefix})},getCommon({name:e="",theme:t={},params:n,set:o,defaults:r}){var a,s,l,i,u,d,c;let{preset:p,options:m}=t,f,y,g,S,$,j,v;if(D(p)&&m.transform!=="strict"){let{primitive:k,semantic:V,extend:G}=p,de=V||{},{colorScheme:ce}=de,be=Se(de,["colorScheme"]),se=G||{},{colorScheme:ne}=se,oe=Se(se,["colorScheme"]),Y=ce||{},{dark:re}=Y,le=Se(Y,["dark"]),Q=ne||{},{dark:_e}=Q,we=Se(Q,["dark"]),pe=D(k)?this._toVariables({primitive:k},m):{},ue=D(be)?this._toVariables({semantic:be},m):{},ye=D(le)?this._toVariables({light:le},m):{},B=D(re)?this._toVariables({dark:re},m):{},$e=D(oe)?this._toVariables({semantic:oe},m):{},ft=D(we)?this._toVariables({light:we},m):{},bt=D(_e)?this._toVariables({dark:_e},m):{},[Et,Lt]=[(a=pe.declarations)!=null?a:"",pe.tokens],[vt,Ie]=[(s=ue.declarations)!=null?s:"",ue.tokens||[]],[Nt,Oe]=[(l=ye.declarations)!=null?l:"",ye.tokens||[]],[jt,gt]=[(i=B.declarations)!=null?i:"",B.tokens||[]],[It,Dt]=[(u=$e.declarations)!=null?u:"",$e.tokens||[]],[ke,Te]=[(d=ft.declarations)!=null?d:"",ft.tokens||[]],[ae,ze]=[(c=bt.declarations)!=null?c:"",bt.tokens||[]];f=this.transformCSS(e,Et,"light","variable",m,o,r),y=Lt;let He=this.transformCSS(e,`${vt}${Nt}`,"light","variable",m,o,r),Rt=this.transformCSS(e,`${jt}`,"dark","variable",m,o,r);g=`${He}${Rt}`,S=[...new Set([...Ie,...Oe,...gt])];let ht=this.transformCSS(e,`${It}${ke}color-scheme:light`,"light","variable",m,o,r),Vt=this.transformCSS(e,`${ae}color-scheme:dark`,"dark","variable",m,o,r);$=`${ht}${Vt}`,j=[...new Set([...Dt,...Te,...ze])],v=ie(p.css,{dt:Ee})}return{primitive:{css:f,tokens:y},semantic:{css:g,tokens:S},global:{css:$,tokens:j},style:v}},getPreset({name:e="",preset:t={},options:n,params:o,set:r,defaults:a,selector:s}){var l,i,u;let d,c,p;if(D(t)&&n.transform!=="strict"){let m=e.replace("-directive",""),f=t,{colorScheme:y,extend:g,css:S}=f,$=Se(f,["colorScheme","extend","css"]),j=g||{},{colorScheme:v}=j,k=Se(j,["colorScheme"]),V=y||{},{dark:G}=V,de=Se(V,["dark"]),ce=v||{},{dark:be}=ce,se=Se(ce,["dark"]),ne=D($)?this._toVariables({[m]:fe(fe({},$),k)},n):{},oe=D(de)?this._toVariables({[m]:fe(fe({},de),se)},n):{},Y=D(G)?this._toVariables({[m]:fe(fe({},G),be)},n):{},[re,le]=[(l=ne.declarations)!=null?l:"",ne.tokens||[]],[Q,_e]=[(i=oe.declarations)!=null?i:"",oe.tokens||[]],[we,pe]=[(u=Y.declarations)!=null?u:"",Y.tokens||[]],ue=this.transformCSS(m,`${re}${Q}`,"light","variable",n,r,a,s),ye=this.transformCSS(m,we,"dark","variable",n,r,a,s);d=`${ue}${ye}`,c=[...new Set([...le,..._e,...pe])],p=ie(S,{dt:Ee})}return{css:d,tokens:c,style:p}},getPresetC({name:e="",theme:t={},params:n,set:o,defaults:r}){var a;let{preset:s,options:l}=t,i=(a=s?.components)==null?void 0:a[e];return this.getPreset({name:e,preset:i,options:l,params:n,set:o,defaults:r})},getPresetD({name:e="",theme:t={},params:n,set:o,defaults:r}){var a,s;let l=e.replace("-directive",""),{preset:i,options:u}=t,d=((a=i?.components)==null?void 0:a[l])||((s=i?.directives)==null?void 0:s[l]);return this.getPreset({name:l,preset:d,options:u,params:n,set:o,defaults:r})},applyDarkColorScheme(e){return!(e.darkModeSelector==="none"||e.darkModeSelector===!1)},getColorSchemeOption(e,t){var n;return this.applyDarkColorScheme(e)?this.regex.resolve(e.darkModeSelector===!0?t.options.darkModeSelector:(n=e.darkModeSelector)!=null?n:t.options.darkModeSelector):[]},getLayerOrder(e,t={},n,o){let{cssLayer:r}=t;return r?`@layer ${ie(r.order||r.name||"primeui",n)}`:""},getCommonStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:a}){let s=this.getCommon({name:e,theme:t,params:n,set:r,defaults:a}),l=Object.entries(o).reduce((i,[u,d])=>i.push(`${u}="${d}"`)&&i,[]).join(" ");return Object.entries(s||{}).reduce((i,[u,d])=>{if(he(d)&&Object.hasOwn(d,"css")){let c=Qe(d.css),p=`${u}-variables`;i.push(`<style type="text/css" data-primevue-style-id="${p}" ${l}>${c}</style>`)}return i},[]).join("")},getStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:a}){var s;let l={name:e,theme:t,params:n,set:r,defaults:a},i=(s=e.includes("-directive")?this.getPresetD(l):this.getPresetC(l))==null?void 0:s.css,u=Object.entries(o).reduce((d,[c,p])=>d.push(`${c}="${p}"`)&&d,[]).join(" ");return i?`<style type="text/css" data-primevue-style-id="${e}-variables" ${u}>${Qe(i)}</style>`:""},createTokens(e={},t,n="",o="",r={}){let a=function(l,i={},u=[]){if(u.includes(this.path))return console.warn(`Circular reference detected at ${this.path}`),{colorScheme:l,path:this.path,paths:i,value:void 0};u.push(this.path),i.name=this.path,i.binding||(i.binding={});let d=this.value;if(typeof this.value=="string"&&nt.test(this.value)){let c=this.value.trim().replace(nt,p=>{var m;let f=p.slice(1,-1),y=this.tokens[f];if(!y)return console.warn(`Token not found for path: ${f}`),"__UNRESOLVED__";let g=y.computed(l,i,u);return Array.isArray(g)&&g.length===2?`light-dark(${g[0].value},${g[1].value})`:(m=g?.value)!=null?m:"__UNRESOLVED__"});d=Jn.test(c.replace(Xn,"0"))?`calc(${c})`:c}return Ne(i.binding)&&delete i.binding,u.pop(),{colorScheme:l,path:this.path,paths:i,value:d.includes("__UNRESOLVED__")?void 0:d}},s=(l,i,u)=>{Object.entries(l).forEach(([d,c])=>{let p=Ae(d,t.variable.excludedKeyRegex)?i:i?`${i}.${vn(d)}`:vn(d),m=u?`${u}.${d}`:d;he(c)?s(c,p,m):(r[p]||(r[p]={paths:[],computed:(f,y={},g=[])=>{if(r[p].paths.length===1)return r[p].paths[0].computed(r[p].paths[0].scheme,y.binding,g);if(f&&f!=="none")for(let S=0;S<r[p].paths.length;S++){let $=r[p].paths[S];if($.scheme===f)return $.computed(f,y.binding,g)}return r[p].paths.map(S=>S.computed(S.scheme,y[S.scheme],g))}}),r[p].paths.push({path:m,value:c,scheme:m.includes("colorScheme.light")?"light":m.includes("colorScheme.dark")?"dark":"none",computed:a,tokens:r}))})};return s(e,n,o),r},getTokenValue(e,t,n){var o;let r=(l=>l.split(".").filter(i=>!Ae(i.toLowerCase(),n.variable.excludedKeyRegex)).join("."))(t),a=t.includes("colorScheme.light")?"light":t.includes("colorScheme.dark")?"dark":void 0,s=[(o=e[r])==null?void 0:o.computed(a)].flat().filter(l=>l);return s.length===1?s[0].value:s.reduce((l={},i)=>{let u=i,{colorScheme:d}=u,c=Se(u,["colorScheme"]);return l[d]=c,l},void 0)},getSelectorRule(e,t,n,o){return n==="class"||n==="attr"?De(D(t)?`${e}${t},${e} ${t}`:e,o):De(e,De(t??":root,:host",o))},transformCSS(e,t,n,o,r={},a,s,l){if(D(t)){let{cssLayer:i}=r;if(o!=="style"){let u=this.getColorSchemeOption(r,s);t=n==="dark"?u.reduce((d,{type:c,selector:p})=>(D(p)&&(d+=p.includes("[CSS]")?p.replace("[CSS]",t):this.getSelectorRule(p,l,c,t)),d),""):De(l??":root,:host",t)}if(i){let u={name:"primeui"};he(i)&&(u.name=ie(i.name,{name:e,type:o})),D(u.name)&&(t=De(`@layer ${u.name}`,t),a?.layerNames(u.name))}return t}return""}},N={defaults:{variable:{prefix:"p",selector:":root,:host",excludedKeyRegex:/^(primitive|semantic|components|directives|variables|colorscheme|light|dark|common|root|states|extend|css)$/gi},options:{prefix:"p",darkModeSelector:"system",cssLayer:!1}},_theme:void 0,_layerNames:new Set,_loadedStyleNames:new Set,_loadingStyles:new Set,_tokens:{},update(e={}){let{theme:t}=e;t&&(this._theme=Mt(fe({},t),{options:fe(fe({},this.defaults.options),t.options)}),this._tokens=me.createTokens(this.preset,this.defaults),this.clearLoadedStyleNames())},get theme(){return this._theme},get preset(){var e;return((e=this.theme)==null?void 0:e.preset)||{}},get options(){var e;return((e=this.theme)==null?void 0:e.options)||{}},get tokens(){return this._tokens},getTheme(){return this.theme},setTheme(e){this.update({theme:e}),z.emit("theme:change",e)},getPreset(){return this.preset},setPreset(e){this._theme=Mt(fe({},this.theme),{preset:e}),this._tokens=me.createTokens(e,this.defaults),this.clearLoadedStyleNames(),z.emit("preset:change",e),z.emit("theme:change",this.theme)},getOptions(){return this.options},setOptions(e){this._theme=Mt(fe({},this.theme),{options:e}),this.clearLoadedStyleNames(),z.emit("options:change",e),z.emit("theme:change",this.theme)},getLayerNames(){return[...this._layerNames]},setLayerNames(e){this._layerNames.add(e)},getLoadedStyleNames(){return this._loadedStyleNames},isStyleNameLoaded(e){return this._loadedStyleNames.has(e)},setLoadedStyleName(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames(){this._loadedStyleNames.clear()},getTokenValue(e){return me.getTokenValue(this.tokens,e,this.defaults)},getCommon(e="",t){return me.getCommon({name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getComponent(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPresetC(n)},getDirective(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPresetD(n)},getCustomPreset(e="",t,n,o){let r={name:e,preset:t,options:this.options,selector:n,params:o,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPreset(r)},getLayerOrderCSS(e=""){return me.getLayerOrder(e,this.options,{names:this.getLayerNames()},this.defaults)},transformCSS(e="",t,n="style",o){return me.transformCSS(e,t,o,n,this.options,{layerNames:this.setLayerNames.bind(this)},this.defaults)},getCommonStyleSheet(e="",t,n={}){return me.getCommonStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getStyleSheet(e,t,n={}){return me.getStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},onStyleMounted(e){this._loadingStyles.add(e)},onStyleUpdated(e){this._loadingStyles.add(e)},onStyleLoaded(e,{name:t}){this._loadingStyles.size&&(this._loadingStyles.delete(t),z.emit(`theme:${t}:load`,e),!this._loadingStyles.size&&z.emit("theme:load"))}},H={STARTS_WITH:"startsWith",CONTAINS:"contains",NOT_CONTAINS:"notContains",ENDS_WITH:"endsWith",EQUALS:"equals",NOT_EQUALS:"notEquals",LESS_THAN:"lt",LESS_THAN_OR_EQUAL_TO:"lte",GREATER_THAN:"gt",GREATER_THAN_OR_EQUAL_TO:"gte",DATE_IS:"dateIs",DATE_IS_NOT:"dateIsNot",DATE_BEFORE:"dateBefore",DATE_AFTER:"dateAfter"},gr=`
    *,
    ::before,
    ::after {
        box-sizing: border-box;
    }

    .p-collapsible-enter-active {
        animation: p-animate-collapsible-expand 0.2s ease-out;
        overflow: hidden;
    }

    .p-collapsible-leave-active {
        animation: p-animate-collapsible-collapse 0.2s ease-out;
        overflow: hidden;
    }

    @keyframes p-animate-collapsible-expand {
        from {
            grid-template-rows: 0fr;
        }
        to {
            grid-template-rows: 1fr;
        }
    }

    @keyframes p-animate-collapsible-collapse {
        from {
            grid-template-rows: 1fr;
        }
        to {
            grid-template-rows: 0fr;
        }
    }

    .p-disabled,
    .p-disabled * {
        cursor: default;
        pointer-events: none;
        user-select: none;
    }

    .p-disabled,
    .p-component:disabled {
        opacity: dt('disabled.opacity');
    }

    .pi {
        font-size: dt('icon.size');
    }

    .p-icon {
        width: dt('icon.size');
        height: dt('icon.size');
    }

    .p-overlay-mask {
        background: var(--px-mask-background, dt('mask.background'));
        color: dt('mask.color');
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
    }

    .p-overlay-mask-enter-active {
        animation: p-animate-overlay-mask-enter dt('mask.transition.duration') forwards;
    }

    .p-overlay-mask-leave-active {
        animation: p-animate-overlay-mask-leave dt('mask.transition.duration') forwards;
    }

    @keyframes p-animate-overlay-mask-enter {
        from {
            background: transparent;
        }
        to {
            background: var(--px-mask-background, dt('mask.background'));
        }
    }
    @keyframes p-animate-overlay-mask-leave {
        from {
            background: var(--px-mask-background, dt('mask.background'));
        }
        to {
            background: transparent;
        }
    }

    .p-anchored-overlay-enter-active {
        animation: p-animate-anchored-overlay-enter 300ms cubic-bezier(.19,1,.22,1);
    }

    .p-anchored-overlay-leave-active {
        animation: p-animate-anchored-overlay-leave 300ms cubic-bezier(.19,1,.22,1);
    }

    @keyframes p-animate-anchored-overlay-enter {
        from {
            opacity: 0;
            transform: scale(0.93);
        }
    }

    @keyframes p-animate-anchored-overlay-leave {
        to {
            opacity: 0;
            transform: scale(0.93);
        }
    }
`;function ot(e){"@babel/helpers - typeof";return ot=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ot(e)}function gn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function hn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?gn(Object(n),!0).forEach(function(o){hr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):gn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function hr(e,t,n){return(t=yr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function yr(e){var t=Sr(e,"string");return ot(t)=="symbol"?t:t+""}function Sr(e,t){if(ot(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ot(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function _r(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0;ln()&&ln().components?Vn(e):t?e():wo(e)}var wr=0;function $r(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},n=M(!1),o=M(e),r=M(null),a=ar()?window.document:void 0,s=t.document,l=s===void 0?a:s,i=t.immediate,u=i===void 0?!0:i,d=t.manual,c=d===void 0?!1:d,p=t.name,m=p===void 0?"style_".concat(++wr):p,f=t.id,y=f===void 0?void 0:f,g=t.media,S=g===void 0?void 0:g,$=t.nonce,j=$===void 0?void 0:$,v=t.first,k=v===void 0?!1:v,V=t.onMounted,G=V===void 0?void 0:V,de=t.onUpdated,ce=de===void 0?void 0:de,be=t.onLoad,se=be===void 0?void 0:be,ne=t.props,oe=ne===void 0?{}:ne,Y=function(){},re=function(_e){var we=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(l){var pe=hn(hn({},oe),we),ue=pe.name||m,ye=pe.id||y,B=pe.nonce||j;r.value=l.querySelector('style[data-primevue-style-id="'.concat(ue,'"]'))||l.getElementById(ye)||l.createElement("style"),r.value.isConnected||(o.value=_e||e,xt(r.value,{type:"text/css",id:ye,media:S,nonce:B}),k?l.head.prepend(r.value):l.head.appendChild(r.value),ir(r.value,"data-primevue-style-id",ue),xt(r.value,pe),r.value.onload=function($e){return se?.($e,{name:ue})},G?.(ue)),!n.value&&(Y=Re(o,function($e){r.value.textContent=$e,ce?.(ue)},{immediate:!0}),n.value=!0)}},le=function(){!l||!n.value||(Y(),Xo(r.value)&&l.head.removeChild(r.value),n.value=!1,r.value=null)};return u&&!c&&_r(re),{id:y,name:m,el:r,css:o,unload:le,load:re,isLoaded:_o(n)}}function rt(e){"@babel/helpers - typeof";return rt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},rt(e)}var yn,Sn,_n,wn;function $n(e,t){return Or(e)||xr(e,t)||Pr(e,t)||kr()}function kr(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Pr(e,t){if(e){if(typeof e=="string")return kn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?kn(e,t):void 0}}function kn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function xr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,a,s,l=[],i=!0,u=!1;try{if(a=(n=n.call(e)).next,t!==0)for(;!(i=(o=a.call(n)).done)&&(l.push(o.value),l.length!==t);i=!0);}catch(d){u=!0,r=d}finally{try{if(!i&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function Or(e){if(Array.isArray(e))return e}function Pn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function Bt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Pn(Object(n),!0).forEach(function(o){Tr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Pn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Tr(e,t,n){return(t=Cr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Cr(e){var t=Ar(e,"string");return rt(t)=="symbol"?t:t+""}function Ar(e,t){if(rt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(rt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function _t(e,t){return t||(t=e.slice(0)),Object.freeze(Object.defineProperties(e,{raw:{value:Object.freeze(t)}}))}var Er=function(t){var n=t.dt;return`
.p-hidden-accessible {
    border: 0;
    clip: rect(0 0 0 0);
    height: 1px;
    margin: -1px;
    opacity: 0;
    overflow: hidden;
    padding: 0;
    pointer-events: none;
    position: absolute;
    white-space: nowrap;
    width: 1px;
}

.p-overflow-hidden {
    overflow: hidden;
    padding-right: `.concat(n("scrollbar.width"),`;
}
`)},Lr={},Nr={},R={name:"base",css:Er,style:gr,classes:Lr,inlineStyles:Nr,load:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:function(a){return a},r=o(St(yn||(yn=_t(["",""])),t));return D(r)?$r(Qe(r),Bt({name:this.name},n)):{}},loadCSS:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};return this.load(this.css,t)},loadStyle:function(){var t=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"";return this.load(this.style,n,function(){var r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"";return N.transformCSS(n.name||t.name,"".concat(r).concat(St(Sn||(Sn=_t(["",""])),o)))})},getCommonTheme:function(t){return N.getCommon(this.name,t)},getComponentTheme:function(t){return N.getComponent(this.name,t)},getDirectiveTheme:function(t){return N.getDirective(this.name,t)},getPresetTheme:function(t,n,o){return N.getCustomPreset(this.name,t,n,o)},getLayerOrderThemeCSS:function(){return N.getLayerOrderCSS(this.name)},getStyleSheet:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(this.css){var o=ie(this.css,{dt:Ee})||"",r=Qe(St(_n||(_n=_t(["","",""])),o,t)),a=Object.entries(n).reduce(function(s,l){var i=$n(l,2),u=i[0],d=i[1];return s.push("".concat(u,'="').concat(d,'"'))&&s},[]).join(" ");return D(r)?'<style type="text/css" data-primevue-style-id="'.concat(this.name,'" ').concat(a,">").concat(r,"</style>"):""}return""},getCommonThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return N.getCommonStyleSheet(this.name,t,n)},getThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=[N.getStyleSheet(this.name,t,n)];if(this.style){var r=this.name==="base"?"global-style":"".concat(this.name,"-style"),a=St(wn||(wn=_t(["",""])),ie(this.style,{dt:Ee})),s=Qe(N.transformCSS(r,a)),l=Object.entries(n).reduce(function(i,u){var d=$n(u,2),c=d[0],p=d[1];return i.push("".concat(c,'="').concat(p,'"'))&&i},[]).join(" ");D(s)&&o.push('<style type="text/css" data-primevue-style-id="'.concat(r,'" ').concat(l,">").concat(s,"</style>"))}return o.join("")},extend:function(t){return Bt(Bt({},this),{},{css:void 0,style:void 0},t)}},xe=zn();function at(e){"@babel/helpers - typeof";return at=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},at(e)}function xn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function wt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?xn(Object(n),!0).forEach(function(o){jr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):xn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function jr(e,t,n){return(t=Ir(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Ir(e){var t=Dr(e,"string");return at(t)=="symbol"?t:t+""}function Dr(e,t){if(at(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(at(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Rr={ripple:!1,inputStyle:null,inputVariant:null,locale:{startsWith:"Starts with",contains:"Contains",notContains:"Not contains",endsWith:"Ends with",equals:"Equals",notEquals:"Not equals",noFilter:"No Filter",lt:"Less than",lte:"Less than or equal to",gt:"Greater than",gte:"Greater than or equal to",dateIs:"Date is",dateIsNot:"Date is not",dateBefore:"Date is before",dateAfter:"Date is after",clear:"Clear",apply:"Apply",matchAll:"Match All",matchAny:"Match Any",addRule:"Add Rule",removeRule:"Remove Rule",accept:"Yes",reject:"No",choose:"Choose",upload:"Upload",cancel:"Cancel",completed:"Completed",pending:"Pending",fileSizeTypes:["B","KB","MB","GB","TB","PB","EB","ZB","YB"],dayNames:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],dayNamesShort:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],dayNamesMin:["Su","Mo","Tu","We","Th","Fr","Sa"],monthNames:["January","February","March","April","May","June","July","August","September","October","November","December"],monthNamesShort:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],chooseYear:"Choose Year",chooseMonth:"Choose Month",chooseDate:"Choose Date",prevDecade:"Previous Decade",nextDecade:"Next Decade",prevYear:"Previous Year",nextYear:"Next Year",prevMonth:"Previous Month",nextMonth:"Next Month",prevHour:"Previous Hour",nextHour:"Next Hour",prevMinute:"Previous Minute",nextMinute:"Next Minute",prevSecond:"Previous Second",nextSecond:"Next Second",am:"am",pm:"pm",today:"Today",weekHeader:"Wk",firstDayOfWeek:0,showMonthAfterYear:!1,dateFormat:"mm/dd/yy",weak:"Weak",medium:"Medium",strong:"Strong",passwordPrompt:"Enter a password",emptyFilterMessage:"No results found",searchMessage:"{0} results are available",selectionMessage:"{0} items selected",emptySelectionMessage:"No selected item",emptySearchMessage:"No results found",fileChosenMessage:"{0} files",noFileChosenMessage:"No file chosen",emptyMessage:"No available options",aria:{trueLabel:"True",falseLabel:"False",nullLabel:"Not Selected",star:"1 star",stars:"{star} stars",selectAll:"All items selected",unselectAll:"All items unselected",close:"Close",previous:"Previous",next:"Next",navigation:"Navigation",scrollTop:"Scroll Top",moveTop:"Move Top",moveUp:"Move Up",moveDown:"Move Down",moveBottom:"Move Bottom",moveToTarget:"Move to Target",moveToSource:"Move to Source",moveAllToTarget:"Move All to Target",moveAllToSource:"Move All to Source",pageLabel:"Page {page}",firstPageLabel:"First Page",lastPageLabel:"Last Page",nextPageLabel:"Next Page",prevPageLabel:"Previous Page",rowsPerPageLabel:"Rows per page",jumpToPageDropdownLabel:"Jump to Page Dropdown",jumpToPageInputLabel:"Jump to Page Input",selectRow:"Row Selected",unselectRow:"Row Unselected",expandRow:"Row Expanded",collapseRow:"Row Collapsed",showFilterMenu:"Show Filter Menu",hideFilterMenu:"Hide Filter Menu",filterOperator:"Filter Operator",filterConstraint:"Filter Constraint",editRow:"Row Edit",saveEdit:"Save Edit",cancelEdit:"Cancel Edit",listView:"List View",gridView:"Grid View",slide:"Slide",slideNumber:"{slideNumber}",zoomImage:"Zoom Image",zoomIn:"Zoom In",zoomOut:"Zoom Out",rotateRight:"Rotate Right",rotateLeft:"Rotate Left",listLabel:"Option List"}},filterMatchModeOptions:{text:[H.STARTS_WITH,H.CONTAINS,H.NOT_CONTAINS,H.ENDS_WITH,H.EQUALS,H.NOT_EQUALS],numeric:[H.EQUALS,H.NOT_EQUALS,H.LESS_THAN,H.LESS_THAN_OR_EQUAL_TO,H.GREATER_THAN,H.GREATER_THAN_OR_EQUAL_TO],date:[H.DATE_IS,H.DATE_IS_NOT,H.DATE_BEFORE,H.DATE_AFTER]},zIndex:{modal:1100,overlay:1e3,menu:1e3,tooltip:1100},theme:void 0,unstyled:!1,pt:void 0,ptOptions:{mergeSections:!0,mergeProps:!1},csp:{nonce:void 0}},Vr=Symbol();function Mr(e,t){var n={config:$o(t)};return e.config.globalProperties.$primevue=n,e.provide(Vr,n),Br(),Wr(e,n),n}var Ve=[];function Br(){z.clear(),Ve.forEach(function(e){return e?.()}),Ve=[]}function Wr(e,t){var n=M(!1),o=function(){var u;if(((u=t.config)===null||u===void 0?void 0:u.theme)!=="none"&&!N.isStyleNameLoaded("common")){var d,c,p=((d=R.getCommonTheme)===null||d===void 0?void 0:d.call(R))||{},m=p.primitive,f=p.semantic,y=p.global,g=p.style,S={nonce:(c=t.config)===null||c===void 0||(c=c.csp)===null||c===void 0?void 0:c.nonce};R.load(m?.css,wt({name:"primitive-variables"},S)),R.load(f?.css,wt({name:"semantic-variables"},S)),R.load(y?.css,wt({name:"global-variables"},S)),R.loadStyle(wt({name:"global-style"},S),g),N.setLoadedStyleName("common")}};z.on("theme:change",function(i){n.value||(e.config.globalProperties.$primevue.config.theme=i,n.value=!0)});var r=Re(t.config,function(i,u){xe.emit("config:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!0}),a=Re(function(){return t.config.ripple},function(i,u){xe.emit("config:ripple:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!0}),s=Re(function(){return t.config.theme},function(i,u){n.value||N.setTheme(i),t.config.unstyled||o(),n.value=!1,xe.emit("config:theme:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!1}),l=Re(function(){return t.config.unstyled},function(i,u){!i&&t.config.theme&&o(),xe.emit("config:unstyled:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!0});Ve.push(r),Ve.push(a),Ve.push(s),Ve.push(l)}var Ur={install:function(t,n){var o=qo(Rr,n);Mr(t,o)}};const zr={install:e=>e.use(Ur,{theme:"none"})};var Pe={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(t){return this._loadedStyleNames.has(t)},setLoadedStyleName:function(t){this._loadedStyleNames.add(t)},deleteLoadedStyleName:function(t){this._loadedStyleNames.delete(t)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function Hr(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",t=ko();return"".concat(e).concat(t.replace("v-","").replaceAll("-","_"))}var On=R.extend({name:"common"});function it(e){"@babel/helpers - typeof";return it=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},it(e)}function qr(e){return ao(e)||Kr(e)||ro(e)||oo()}function Kr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function qe(e,t){return ao(e)||Fr(e,t)||ro(e,t)||oo()}function oo(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ro(e,t){if(e){if(typeof e=="string")return Zt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Zt(e,t):void 0}}function Zt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Fr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,a,s,l=[],i=!0,u=!1;try{if(a=(n=n.call(e)).next,t===0){if(Object(n)!==n)return;i=!1}else for(;!(i=(o=a.call(n)).done)&&(l.push(o.value),l.length!==t);i=!0);}catch(d){u=!0,r=d}finally{try{if(!i&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function ao(e){if(Array.isArray(e))return e}function Tn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function x(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Tn(Object(n),!0).forEach(function(o){Ye(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Tn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ye(e,t,n){return(t=Gr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Gr(e){var t=Yr(e,"string");return it(t)=="symbol"?t:t+""}function Yr(e,t){if(it(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(it(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var nn={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(t){z.off("theme:change",this._loadCoreStyles),t||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(t,n){var o=this;z.off("theme:change",this._themeScopedListener),t?(this._loadScopedThemeStyles(t),this._themeScopedListener=function(){return o._loadScopedThemeStyles(t)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var t,n,o,r,a,s,l,i,u,d,c,p=(t=this.pt)===null||t===void 0?void 0:t._usept,m=p?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,f=p?(o=this.pt)===null||o===void 0||(o=o.value)===null||o===void 0?void 0:o[this.$.type.name]:this.pt;(r=f||m)===null||r===void 0||(r=r.hooks)===null||r===void 0||(a=r.onBeforeCreate)===null||a===void 0||a.call(r);var y=(s=this.$primevueConfig)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s._usept,g=y?(l=this.$primevue)===null||l===void 0||(l=l.config)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l.originalValue:void 0,S=y?(i=this.$primevue)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.pt)===null||i===void 0?void 0:i.value:(u=this.$primevue)===null||u===void 0||(u=u.config)===null||u===void 0?void 0:u.pt;(d=S||g)===null||d===void 0||(d=d[this.$.type.name])===null||d===void 0||(d=d.hooks)===null||d===void 0||(c=d.onBeforeCreate)===null||c===void 0||c.call(d),this.$attrSelector=Hr(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var t;this.rootEl=Fn(je(this.$el)?this.$el:(t=this.$el)===null||t===void 0?void 0:t.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=x({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(t){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(t)),o=this._useDefaultPT(this._getOptionValue,"hooks.".concat(t));n?.(),o?.()}},_mergeProps:function(t){for(var n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return Ct(t)?t.apply(void 0,o):X.apply(void 0,o)},_load:function(){Pe.isStyleNameLoaded("base")||(R.loadCSS(this.$styleOptions),this._loadGlobalStyles(),Pe.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var t,n;!Pe.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(On.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),Pe.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var t=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);D(t)&&R.load(t,x({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var t,n;if(!(this.isUnstyled||this.$theme==="none")){if(!N.isStyleNameLoaded("common")){var o,r,a=((o=this.$style)===null||o===void 0||(r=o.getCommonTheme)===null||r===void 0?void 0:r.call(o))||{},s=a.primitive,l=a.semantic,i=a.global,u=a.style;R.load(s?.css,x({name:"primitive-variables"},this.$styleOptions)),R.load(l?.css,x({name:"semantic-variables"},this.$styleOptions)),R.load(i?.css,x({name:"global-variables"},this.$styleOptions)),R.loadStyle(x({name:"global-style"},this.$styleOptions),u),N.setLoadedStyleName("common")}if(!N.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var d,c,p,m,f=((d=this.$style)===null||d===void 0||(c=d.getComponentTheme)===null||c===void 0?void 0:c.call(d))||{},y=f.css,g=f.style;(p=this.$style)===null||p===void 0||p.load(y,x({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(m=this.$style)===null||m===void 0||m.loadStyle(x({name:"".concat(this.$style.name,"-style")},this.$styleOptions),g),N.setLoadedStyleName(this.$style.name)}if(!N.isStyleNameLoaded("layer-order")){var S,$,j=(S=this.$style)===null||S===void 0||($=S.getLayerOrderThemeCSS)===null||$===void 0?void 0:$.call(S);R.load(j,x({name:"layer-order",first:!0},this.$styleOptions)),N.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(t){var n,o,r,a=((n=this.$style)===null||n===void 0||(o=n.getPresetTheme)===null||o===void 0?void 0:o.call(n,t,"[".concat(this.$attrSelector,"]")))||{},s=a.css,l=(r=this.$style)===null||r===void 0?void 0:r.load(s,x({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=l.el},_unloadScopedThemeStyles:function(){var t;(t=this.scopedStyleEl)===null||t===void 0||(t=t.value)===null||t===void 0||t.remove()},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};Pe.clearLoadedStyleNames(),z.on("theme:change",t)},_removeThemeListeners:function(){z.off("theme:change",this._loadCoreStyles),z.off("theme:change",this._load),z.off("theme:change",this._themeScopedListener)},_getHostInstance:function(t){return t?this.$options.hostName?t.$.type.name===this.$options.hostName?t:this._getHostInstance(t.$parentInstance):t.$parentInstance:void 0},_getPropValue:function(t){var n;return this[t]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[t])},_getOptionValue:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return tn(t,n,o)},_getPTValue:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,s=/./g.test(o)&&!!r[o.split(".")[0]],l=this._getPropValue("ptOptions")||((t=this.$primevueConfig)===null||t===void 0?void 0:t.ptOptions)||{},i=l.mergeSections,u=i===void 0?!0:i,d=l.mergeProps,c=d===void 0?!1:d,p=a?s?this._useGlobalPT(this._getPTClassValue,o,r):this._useDefaultPT(this._getPTClassValue,o,r):void 0,m=s?void 0:this._getPTSelf(n,this._getPTClassValue,o,x(x({},r),{},{global:p||{}})),f=this._getPTDatasets(o);return u||!u&&m?c?this._mergeProps(c,p,m,f):x(x(x({},p),m),f):x(x({},m),f)},_getPTSelf:function(){for(var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return X(this._usePT.apply(this,[this._getPT(t,this.$name)].concat(o)),this._usePT.apply(this,[this.$_attrsPT].concat(o)))},_getPTDatasets:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r="data-pc-",a=o==="root"&&D((t=this.pt)===null||t===void 0?void 0:t["data-pc-section"]);return o!=="transition"&&x(x({},o==="root"&&x(x(Ye({},"".concat(r,"name"),ge(a?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),a&&Ye({},"".concat(r,"extend"),ge(this.$.type.name))),{},Ye({},"".concat(this.$attrSelector),""))),{},Ye({},"".concat(r,"section"),ge(o)))},_getPTClassValue:function(){var t=this._getOptionValue.apply(this,arguments);return te(t)||Wn(t)?{class:t}:t},_getPT:function(t){var n=this,o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,a=function(l){var i,u=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,d=r?r(l):l,c=ge(o),p=ge(n.$name);return(i=u?c!==p?d?.[c]:void 0:d?.[c])!==null&&i!==void 0?i:d};return t!=null&&t.hasOwnProperty("_usept")?{_usept:t._usept,originalValue:a(t.originalValue),value:a(t.value)}:a(t,!0)},_usePT:function(t,n,o,r){var a=function(y){return n(y,o,r)};if(t!=null&&t.hasOwnProperty("_usept")){var s,l=t._usept||((s=this.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},i=l.mergeSections,u=i===void 0?!0:i,d=l.mergeProps,c=d===void 0?!1:d,p=a(t.originalValue),m=a(t.value);return p===void 0&&m===void 0?void 0:te(m)?m:te(p)?p:u||!u&&m?c?this._mergeProps(c,p,m):x(x({},p),m):m}return a(t)},_useGlobalPT:function(t,n,o){return this._usePT(this.globalPT,t,n,o)},_useDefaultPT:function(t,n,o){return this._usePT(this.defaultPT,t,n,o)},ptm:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,t,x(x({},this.$params),n))},ptmi:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=X(this.$_attrsWithoutPT,this.ptm(n,o));return r?.hasOwnProperty("id")&&((t=r.id)!==null&&t!==void 0||(r.id=this.$id)),r},ptmo:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(t,n,x({instance:this},o),!1)},cx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,t,x(x({},this.$params),n))},sx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var r=this._getOptionValue(this.$style.inlineStyles,t,x(x({},this.$params),o)),a=this._getOptionValue(On.inlineStyles,t,x(x({},this.$params),o));return[a,r]}}},computed:{globalPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return ie(o,{instance:n})})},defaultPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return n._getOptionValue(o,n.$name,x({},n.$params))||ie(o,x({},n.$params))})},isUnstyled:function(){var t;return this.unstyled!==void 0?this.unstyled:(t=this.$primevueConfig)===null||t===void 0?void 0:t.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var t,n=Object.keys(((t=this.$.vnode)===null||t===void 0?void 0:t.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(o){var r=qe(o,1),a=r[0];return n?.includes(a)}))},$theme:function(){var t;return(t=this.$primevueConfig)===null||t===void 0?void 0:t.theme},$style:function(){return x(x({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var t;return{nonce:(t=this.$primevueConfig)===null||t===void 0||(t=t.csp)===null||t===void 0?void 0:t.nonce}},$primevueConfig:function(){var t;return(t=this.$primevue)===null||t===void 0?void 0:t.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var t=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:t,props:t?.$props,state:t?.$data,attrs:t?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=qe(t,1),o=n[0];return o?.startsWith("pt:")}).reduce(function(t,n){var o=qe(n,2),r=o[0],a=o[1],s=r.split(":"),l=qr(s),i=Zt(l).slice(1);return i?.reduce(function(u,d,c,p){return!u[d]&&(u[d]=c===p.length-1?a:{}),u[d]},t),t},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=qe(t,1),o=n[0];return!(o!=null&&o.startsWith("pt:"))}).reduce(function(t,n){var o=qe(n,2),r=o[0],a=o[1];return t[r]=a,t},{})}}},Qr=`
.p-icon {
    display: inline-block;
    vertical-align: baseline;
    flex-shrink: 0;
}

.p-icon-spin {
    -webkit-animation: p-icon-spin 2s infinite linear;
    animation: p-icon-spin 2s infinite linear;
}

@-webkit-keyframes p-icon-spin {
    0% {
        -webkit-transform: rotate(0deg);
        transform: rotate(0deg);
    }
    100% {
        -webkit-transform: rotate(359deg);
        transform: rotate(359deg);
    }
}

@keyframes p-icon-spin {
    0% {
        -webkit-transform: rotate(0deg);
        transform: rotate(0deg);
    }
    100% {
        -webkit-transform: rotate(359deg);
        transform: rotate(359deg);
    }
}
`,Zr=R.extend({name:"baseicon",css:Qr});function st(e){"@babel/helpers - typeof";return st=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},st(e)}function Cn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function An(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Cn(Object(n),!0).forEach(function(o){Jr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Cn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Jr(e,t,n){return(t=Xr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Xr(e){var t=ea(e,"string");return st(t)=="symbol"?t:t+""}function ea(e,t){if(st(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(st(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var ta={name:"BaseIcon",extends:nn,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:Zr,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var t=Ne(this.label);return An(An({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:t?void 0:"img","aria-label":t?void 0:this.label,"aria-hidden":t})}}},io={name:"SpinnerIcon",extends:ta};function na(e){return ia(e)||aa(e)||ra(e)||oa()}function oa(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ra(e,t){if(e){if(typeof e=="string")return Jt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Jt(e,t):void 0}}function aa(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function ia(e){if(Array.isArray(e))return Jt(e)}function Jt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function sa(e,t,n,o,r,a){return O(),L("svg",X({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},e.pti()),na(t[0]||(t[0]=[W("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}io.render=sa;var la=`
    .p-badge {
        display: inline-flex;
        border-radius: dt('badge.border.radius');
        align-items: center;
        justify-content: center;
        padding: dt('badge.padding');
        background: dt('badge.primary.background');
        color: dt('badge.primary.color');
        font-size: dt('badge.font.size');
        font-weight: dt('badge.font.weight');
        min-width: dt('badge.min.width');
        height: dt('badge.height');
    }

    .p-badge-dot {
        width: dt('badge.dot.size');
        min-width: dt('badge.dot.size');
        height: dt('badge.dot.size');
        border-radius: 50%;
        padding: 0;
    }

    .p-badge-circle {
        padding: 0;
        border-radius: 50%;
    }

    .p-badge-secondary {
        background: dt('badge.secondary.background');
        color: dt('badge.secondary.color');
    }

    .p-badge-success {
        background: dt('badge.success.background');
        color: dt('badge.success.color');
    }

    .p-badge-info {
        background: dt('badge.info.background');
        color: dt('badge.info.color');
    }

    .p-badge-warn {
        background: dt('badge.warn.background');
        color: dt('badge.warn.color');
    }

    .p-badge-danger {
        background: dt('badge.danger.background');
        color: dt('badge.danger.color');
    }

    .p-badge-contrast {
        background: dt('badge.contrast.background');
        color: dt('badge.contrast.color');
    }

    .p-badge-sm {
        font-size: dt('badge.sm.font.size');
        min-width: dt('badge.sm.min.width');
        height: dt('badge.sm.height');
    }

    .p-badge-lg {
        font-size: dt('badge.lg.font.size');
        min-width: dt('badge.lg.min.width');
        height: dt('badge.lg.height');
    }

    .p-badge-xl {
        font-size: dt('badge.xl.font.size');
        min-width: dt('badge.xl.min.width');
        height: dt('badge.xl.height');
    }
`,ua={root:function(t){var n=t.props,o=t.instance;return["p-badge p-component",{"p-badge-circle":D(n.value)&&String(n.value).length===1,"p-badge-dot":Ne(n.value)&&!o.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},da=R.extend({name:"badge",style:la,classes:ua}),ca={name:"BaseBadge",extends:nn,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:da,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function lt(e){"@babel/helpers - typeof";return lt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},lt(e)}function En(e,t,n){return(t=pa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function pa(e){var t=ma(e,"string");return lt(t)=="symbol"?t:t+""}function ma(e,t){if(lt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(lt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var so={name:"Badge",extends:ca,inheritAttrs:!1,computed:{dataP:function(){return Ze(En(En({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},fa=["data-p"];function ba(e,t,n,o,r,a){return O(),L("span",X({class:e.cx("root"),"data-p":a.dataP},e.ptmi("root")),[Fe(e.$slots,"default",{},function(){return[Xe(ee(e.value),1)]})],16,fa)}so.render=ba;function ut(e){"@babel/helpers - typeof";return ut=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ut(e)}function Ln(e,t){return ya(e)||ha(e,t)||ga(e,t)||va()}function va(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ga(e,t){if(e){if(typeof e=="string")return Nn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Nn(e,t):void 0}}function Nn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function ha(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,a,s,l=[],i=!0,u=!1;try{if(a=(n=n.call(e)).next,t!==0)for(;!(i=(o=a.call(n)).done)&&(l.push(o.value),l.length!==t);i=!0);}catch(d){u=!0,r=d}finally{try{if(!i&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function ya(e){if(Array.isArray(e))return e}function jn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function T(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?jn(Object(n),!0).forEach(function(o){Xt(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):jn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Xt(e,t,n){return(t=Sa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Sa(e){var t=_a(e,"string");return ut(t)=="symbol"?t:t+""}function _a(e,t){if(ut(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ut(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var w={_getMeta:function(){return[he(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],ie(he(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(t,n){var o,r,a;return(o=(t==null||(r=t.instance)===null||r===void 0?void 0:r.$primevue)||(n==null||(a=n.ctx)===null||a===void 0||(a=a.appContext)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.globalProperties)===null||a===void 0?void 0:a.$primevue))===null||o===void 0?void 0:o.config},_getOptionValue:tn,_getPTValue:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},a=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",s=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},l=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,i=function(){var $=w._getOptionValue.apply(w,arguments);return te($)||Wn($)?{class:$}:$},u=((t=o.binding)===null||t===void 0||(t=t.value)===null||t===void 0?void 0:t.ptOptions)||((n=o.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},d=u.mergeSections,c=d===void 0?!0:d,p=u.mergeProps,m=p===void 0?!1:p,f=l?w._useDefaultPT(o,o.defaultPT(),i,a,s):void 0,y=w._usePT(o,w._getPT(r,o.$name),i,a,T(T({},s),{},{global:f||{}})),g=w._getPTDatasets(o,a);return c||!c&&y?m?w._mergeProps(o,m,f,y,g):T(T(T({},f),y),g):T(T({},y),g)},_getPTDatasets:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o="data-pc-";return T(T({},n==="root"&&Xt({},"".concat(o,"name"),ge(t.$name))),{},Xt({},"".concat(o,"section"),ge(n)))},_getPT:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,r=function(s){var l,i=o?o(s):s,u=ge(n);return(l=i?.[u])!==null&&l!==void 0?l:i};return t&&Object.hasOwn(t,"_usept")?{_usept:t._usept,originalValue:r(t.originalValue),value:r(t.value)}:r(t)},_usePT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0,s=function(g){return o(g,r,a)};if(n&&Object.hasOwn(n,"_usept")){var l,i=n._usept||((l=t.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},u=i.mergeSections,d=u===void 0?!0:u,c=i.mergeProps,p=c===void 0?!1:c,m=s(n.originalValue),f=s(n.value);return m===void 0&&f===void 0?void 0:te(f)?f:te(m)?m:d||!d&&f?p?w._mergeProps(t,p,m,f):T(T({},m),f):f}return s(n)},_useDefaultPT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0;return w._usePT(t,n,o,r,a)},_loadStyles:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,a=w._getConfig(o,r),s={nonce:a==null||(t=a.csp)===null||t===void 0?void 0:t.nonce};w._loadCoreStyles(n,s),w._loadThemeStyles(n,s),w._loadScopedThemeStyles(n,s),w._removeThemeListeners(n),n.$loadStyles=function(){return w._loadThemeStyles(n,s)},w._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0;if(!Pe.isStyleNameLoaded((t=o.$style)===null||t===void 0?void 0:t.name)&&(n=o.$style)!==null&&n!==void 0&&n.name){var a;R.loadCSS(r),(a=o.$style)===null||a===void 0||a.loadCSS(r),Pe.setLoadedStyleName(o.$style.name)}},_loadThemeStyles:function(){var t,n,o,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},a=arguments.length>1?arguments[1]:void 0;if(!(r!=null&&r.isUnstyled()||(r==null||(t=r.theme)===null||t===void 0?void 0:t.call(r))==="none")){if(!N.isStyleNameLoaded("common")){var s,l,i=((s=r.$style)===null||s===void 0||(l=s.getCommonTheme)===null||l===void 0?void 0:l.call(s))||{},u=i.primitive,d=i.semantic,c=i.global,p=i.style;R.load(u?.css,T({name:"primitive-variables"},a)),R.load(d?.css,T({name:"semantic-variables"},a)),R.load(c?.css,T({name:"global-variables"},a)),R.loadStyle(T({name:"global-style"},a),p),N.setLoadedStyleName("common")}if(!N.isStyleNameLoaded((n=r.$style)===null||n===void 0?void 0:n.name)&&(o=r.$style)!==null&&o!==void 0&&o.name){var m,f,y,g,S=((m=r.$style)===null||m===void 0||(f=m.getDirectiveTheme)===null||f===void 0?void 0:f.call(m))||{},$=S.css,j=S.style;(y=r.$style)===null||y===void 0||y.load($,T({name:"".concat(r.$style.name,"-variables")},a)),(g=r.$style)===null||g===void 0||g.loadStyle(T({name:"".concat(r.$style.name,"-style")},a),j),N.setLoadedStyleName(r.$style.name)}if(!N.isStyleNameLoaded("layer-order")){var v,k,V=(v=r.$style)===null||v===void 0||(k=v.getLayerOrderThemeCSS)===null||k===void 0?void 0:k.call(v);R.load(V,T({name:"layer-order",first:!0},a)),N.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=t.preset();if(o&&t.$attrSelector){var r,a,s,l=((r=t.$style)===null||r===void 0||(a=r.getPresetTheme)===null||a===void 0?void 0:a.call(r,o,"[".concat(t.$attrSelector,"]")))||{},i=l.css,u=(s=t.$style)===null||s===void 0?void 0:s.load(i,T({name:"".concat(t.$attrSelector,"-").concat(t.$style.name)},n));t.scopedStyleEl=u.el}},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};Pe.clearLoadedStyleNames(),z.on("theme:change",t)},_removeThemeListeners:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};z.off("theme:change",t.$loadStyles),t.$loadStyles=void 0},_hook:function(t,n,o,r,a,s){var l,i,u="on".concat(Ko(n)),d=w._getConfig(r,a),c=o?.$instance,p=w._usePT(c,w._getPT(r==null||(l=r.value)===null||l===void 0?void 0:l.pt,t),w._getOptionValue,"hooks.".concat(u)),m=w._useDefaultPT(c,d==null||(i=d.pt)===null||i===void 0||(i=i.directives)===null||i===void 0?void 0:i[t],w._getOptionValue,"hooks.".concat(u)),f={el:o,binding:r,vnode:a,prevVnode:s};p?.(c,f),m?.(c,f)},_mergeProps:function(){for(var t=arguments.length>1?arguments[1]:void 0,n=arguments.length,o=new Array(n>2?n-2:0),r=2;r<n;r++)o[r-2]=arguments[r];return Ct(t)?t.apply(void 0,o):X.apply(void 0,o)},_extend:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=function(l,i,u,d,c){var p,m,f,y;i._$instances=i._$instances||{};var g=w._getConfig(u,d),S=i._$instances[t]||{},$=Ne(S)?T(T({},n),n?.methods):{};i._$instances[t]=T(T({},S),{},{$name:t,$host:i,$binding:u,$modifiers:u?.modifiers,$value:u?.value,$el:S.$el||i||void 0,$style:T({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:g,$attrSelector:(p=i.$pd)===null||p===void 0||(p=p[t])===null||p===void 0?void 0:p.attrSelector,defaultPT:function(){return w._getPT(g?.pt,void 0,function(v){var k;return v==null||(k=v.directives)===null||k===void 0?void 0:k[t]})},isUnstyled:function(){var v,k;return((v=i._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.unstyled)!==void 0?(k=i._$instances[t])===null||k===void 0||(k=k.$binding)===null||k===void 0||(k=k.value)===null||k===void 0?void 0:k.unstyled:g?.unstyled},theme:function(){var v;return(v=i._$instances[t])===null||v===void 0||(v=v.$primevueConfig)===null||v===void 0?void 0:v.theme},preset:function(){var v;return(v=i._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.dt},ptm:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",V=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return w._getPTValue(i._$instances[t],(v=i._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.pt,k,T({},V))},ptmo:function(){var v=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},k=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",V=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return w._getPTValue(i._$instances[t],v,k,V,!1)},cx:function(){var v,k,V=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",G=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(v=i._$instances[t])!==null&&v!==void 0&&v.isUnstyled()?void 0:w._getOptionValue((k=i._$instances[t])===null||k===void 0||(k=k.$style)===null||k===void 0?void 0:k.classes,V,T({},G))},sx:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",V=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,G=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return V?w._getOptionValue((v=i._$instances[t])===null||v===void 0||(v=v.$style)===null||v===void 0?void 0:v.inlineStyles,k,T({},G)):void 0}},$),i.$instance=i._$instances[t],(m=(f=i.$instance)[l])===null||m===void 0||m.call(f,i,u,d,c),i["$".concat(t)]=i.$instance,w._hook(t,l,i,u,d,c),i.$pd||(i.$pd={}),i.$pd[t]=T(T({},(y=i.$pd)===null||y===void 0?void 0:y[t]),{},{name:t,instance:i._$instances[t]})},r=function(l){var i,u,d,c=l._$instances[t],p=c?.watch,m=function(g){var S,$=g.newValue,j=g.oldValue;return p==null||(S=p.config)===null||S===void 0?void 0:S.call(c,$,j)},f=function(g){var S,$=g.newValue,j=g.oldValue;return p==null||(S=p["config.ripple"])===null||S===void 0?void 0:S.call(c,$,j)};c.$watchersCallback={config:m,"config.ripple":f},p==null||(i=p.config)===null||i===void 0||i.call(c,c?.$primevueConfig),xe.on("config:change",m),p==null||(u=p["config.ripple"])===null||u===void 0||u.call(c,c==null||(d=c.$primevueConfig)===null||d===void 0?void 0:d.ripple),xe.on("config:ripple:change",f)},a=function(l){var i=l._$instances[t].$watchersCallback;i&&(xe.off("config:change",i.config),xe.off("config:ripple:change",i["config.ripple"]),l._$instances[t].$watchersCallback=void 0)};return{created:function(l,i,u,d){l.$pd||(l.$pd={}),l.$pd[t]={name:t,attrSelector:sr("pd")},o("created",l,i,u,d)},beforeMount:function(l,i,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,i,u),o("beforeMount",l,i,u,d),r(l)},mounted:function(l,i,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,i,u),o("mounted",l,i,u,d)},beforeUpdate:function(l,i,u,d){o("beforeUpdate",l,i,u,d)},updated:function(l,i,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,i,u),o("updated",l,i,u,d)},beforeUnmount:function(l,i,u,d){var c;a(l),w._removeThemeListeners((c=l.$pd[t])===null||c===void 0?void 0:c.instance),o("beforeUnmount",l,i,u,d)},unmounted:function(l,i,u,d){var c;(c=l.$pd[t])===null||c===void 0||(c=c.instance)===null||c===void 0||(c=c.scopedStyleEl)===null||c===void 0||(c=c.value)===null||c===void 0||c.remove(),o("unmounted",l,i,u,d)}}},extend:function(){var t=w._getMeta.apply(w,arguments),n=Ln(t,2),o=n[0],r=n[1];return T({extend:function(){var s=w._getMeta.apply(w,arguments),l=Ln(s,2),i=l[0],u=l[1];return w.extend(i,T(T(T({},r),r?.methods),u))}},w._extend(o,r))}},wa=`
    .p-ink {
        display: block;
        position: absolute;
        background: dt('ripple.background');
        border-radius: 100%;
        transform: scale(0);
        pointer-events: none;
    }

    .p-ink-active {
        animation: ripple 0.4s linear;
    }

    @keyframes ripple {
        100% {
            opacity: 0;
            transform: scale(2.5);
        }
    }
`,$a={root:"p-ink"},ka=R.extend({name:"ripple-directive",style:wa,classes:$a}),Pa=w.extend({style:ka});function dt(e){"@babel/helpers - typeof";return dt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},dt(e)}function xa(e){return Aa(e)||Ca(e)||Ta(e)||Oa()}function Oa(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Ta(e,t){if(e){if(typeof e=="string")return en(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?en(e,t):void 0}}function Ca(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function Aa(e){if(Array.isArray(e))return en(e)}function en(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function In(e,t,n){return(t=Ea(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Ea(e){var t=La(e,"string");return dt(t)=="symbol"?t:t+""}function La(e,t){if(dt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(dt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Na=Pa.extend("ripple",{watch:{"config.ripple":function(t){t?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(t){this.remove(t)},timeout:void 0,methods:{bindEvents:function(t){t.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(t){t.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(t){var n=this.getInk(t);n||(n=er("span",In(In({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),t.appendChild(n),this.$el=n)},remove:function(t){var n=this.getInk(t);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(t),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(t){var n=this,o=t.currentTarget,r=this.getInk(o);if(!(!r||getComputedStyle(r,null).display==="none")){if(!this.isUnstyled()&&Je(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"),!mn(r)&&!fn(r)){var a=Math.max(Jo(o),rr(o));r.style.height=a+"px",r.style.width=a+"px"}var s=or(o),l=t.pageX-s.left+document.body.scrollTop-fn(r)/2,i=t.pageY-s.top+document.body.scrollLeft-mn(r)/2;r.style.top=i+"px",r.style.left=l+"px",!this.isUnstyled()&&Kt(r,"p-ink-active"),r.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){r&&(!n.isUnstyled()&&Je(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(t){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&Je(t.currentTarget,"p-ink-active"),t.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(t){return t&&t.children?xa(t.children).find(function(n){return nr(n,"data-pc-name")==="ripple"}):void 0}}}),ja=`
    .p-button {
        display: inline-flex;
        cursor: pointer;
        user-select: none;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        position: relative;
        color: dt('button.primary.color');
        background: dt('button.primary.background');
        border: 1px solid dt('button.primary.border.color');
        padding: dt('button.padding.y') dt('button.padding.x');
        font-size: 1rem;
        font-family: inherit;
        font-feature-settings: inherit;
        transition:
            background dt('button.transition.duration'),
            color dt('button.transition.duration'),
            border-color dt('button.transition.duration'),
            outline-color dt('button.transition.duration'),
            box-shadow dt('button.transition.duration');
        border-radius: dt('button.border.radius');
        outline-color: transparent;
        gap: dt('button.gap');
    }

    .p-button:disabled {
        cursor: default;
    }

    .p-button-icon-right {
        order: 1;
    }

    .p-button-icon-right:dir(rtl) {
        order: -1;
    }

    .p-button:not(.p-button-vertical) .p-button-icon:not(.p-button-icon-right):dir(rtl) {
        order: 1;
    }

    .p-button-icon-bottom {
        order: 2;
    }

    .p-button-icon-only {
        width: dt('button.icon.only.width');
        padding-inline-start: 0;
        padding-inline-end: 0;
        gap: 0;
    }

    .p-button-icon-only.p-button-rounded {
        border-radius: 50%;
        height: dt('button.icon.only.width');
    }

    .p-button-icon-only .p-button-label {
        visibility: hidden;
        width: 0;
    }

    .p-button-icon-only::after {
        content: " ";
        visibility: hidden;
        width: 0;
    }

    .p-button-sm {
        font-size: dt('button.sm.font.size');
        padding: dt('button.sm.padding.y') dt('button.sm.padding.x');
    }

    .p-button-sm .p-button-icon {
        font-size: dt('button.sm.font.size');
    }

    .p-button-sm.p-button-icon-only {
        width: dt('button.sm.icon.only.width');
    }

    .p-button-sm.p-button-icon-only.p-button-rounded {
        height: dt('button.sm.icon.only.width');
    }

    .p-button-lg {
        font-size: dt('button.lg.font.size');
        padding: dt('button.lg.padding.y') dt('button.lg.padding.x');
    }

    .p-button-lg .p-button-icon {
        font-size: dt('button.lg.font.size');
    }

    .p-button-lg.p-button-icon-only {
        width: dt('button.lg.icon.only.width');
    }

    .p-button-lg.p-button-icon-only.p-button-rounded {
        height: dt('button.lg.icon.only.width');
    }

    .p-button-vertical {
        flex-direction: column;
    }

    .p-button-label {
        font-weight: dt('button.label.font.weight');
    }

    .p-button-fluid {
        width: 100%;
    }

    .p-button-fluid.p-button-icon-only {
        width: dt('button.icon.only.width');
    }

    .p-button:not(:disabled):hover {
        background: dt('button.primary.hover.background');
        border: 1px solid dt('button.primary.hover.border.color');
        color: dt('button.primary.hover.color');
    }

    .p-button:not(:disabled):active {
        background: dt('button.primary.active.background');
        border: 1px solid dt('button.primary.active.border.color');
        color: dt('button.primary.active.color');
    }

    .p-button:focus-visible {
        box-shadow: dt('button.primary.focus.ring.shadow');
        outline: dt('button.focus.ring.width') dt('button.focus.ring.style') dt('button.primary.focus.ring.color');
        outline-offset: dt('button.focus.ring.offset');
    }

    .p-button .p-badge {
        min-width: dt('button.badge.size');
        height: dt('button.badge.size');
        line-height: dt('button.badge.size');
    }

    .p-button-raised {
        box-shadow: dt('button.raised.shadow');
    }

    .p-button-rounded {
        border-radius: dt('button.rounded.border.radius');
    }

    .p-button-secondary {
        background: dt('button.secondary.background');
        border: 1px solid dt('button.secondary.border.color');
        color: dt('button.secondary.color');
    }

    .p-button-secondary:not(:disabled):hover {
        background: dt('button.secondary.hover.background');
        border: 1px solid dt('button.secondary.hover.border.color');
        color: dt('button.secondary.hover.color');
    }

    .p-button-secondary:not(:disabled):active {
        background: dt('button.secondary.active.background');
        border: 1px solid dt('button.secondary.active.border.color');
        color: dt('button.secondary.active.color');
    }

    .p-button-secondary:focus-visible {
        outline-color: dt('button.secondary.focus.ring.color');
        box-shadow: dt('button.secondary.focus.ring.shadow');
    }

    .p-button-success {
        background: dt('button.success.background');
        border: 1px solid dt('button.success.border.color');
        color: dt('button.success.color');
    }

    .p-button-success:not(:disabled):hover {
        background: dt('button.success.hover.background');
        border: 1px solid dt('button.success.hover.border.color');
        color: dt('button.success.hover.color');
    }

    .p-button-success:not(:disabled):active {
        background: dt('button.success.active.background');
        border: 1px solid dt('button.success.active.border.color');
        color: dt('button.success.active.color');
    }

    .p-button-success:focus-visible {
        outline-color: dt('button.success.focus.ring.color');
        box-shadow: dt('button.success.focus.ring.shadow');
    }

    .p-button-info {
        background: dt('button.info.background');
        border: 1px solid dt('button.info.border.color');
        color: dt('button.info.color');
    }

    .p-button-info:not(:disabled):hover {
        background: dt('button.info.hover.background');
        border: 1px solid dt('button.info.hover.border.color');
        color: dt('button.info.hover.color');
    }

    .p-button-info:not(:disabled):active {
        background: dt('button.info.active.background');
        border: 1px solid dt('button.info.active.border.color');
        color: dt('button.info.active.color');
    }

    .p-button-info:focus-visible {
        outline-color: dt('button.info.focus.ring.color');
        box-shadow: dt('button.info.focus.ring.shadow');
    }

    .p-button-warn {
        background: dt('button.warn.background');
        border: 1px solid dt('button.warn.border.color');
        color: dt('button.warn.color');
    }

    .p-button-warn:not(:disabled):hover {
        background: dt('button.warn.hover.background');
        border: 1px solid dt('button.warn.hover.border.color');
        color: dt('button.warn.hover.color');
    }

    .p-button-warn:not(:disabled):active {
        background: dt('button.warn.active.background');
        border: 1px solid dt('button.warn.active.border.color');
        color: dt('button.warn.active.color');
    }

    .p-button-warn:focus-visible {
        outline-color: dt('button.warn.focus.ring.color');
        box-shadow: dt('button.warn.focus.ring.shadow');
    }

    .p-button-help {
        background: dt('button.help.background');
        border: 1px solid dt('button.help.border.color');
        color: dt('button.help.color');
    }

    .p-button-help:not(:disabled):hover {
        background: dt('button.help.hover.background');
        border: 1px solid dt('button.help.hover.border.color');
        color: dt('button.help.hover.color');
    }

    .p-button-help:not(:disabled):active {
        background: dt('button.help.active.background');
        border: 1px solid dt('button.help.active.border.color');
        color: dt('button.help.active.color');
    }

    .p-button-help:focus-visible {
        outline-color: dt('button.help.focus.ring.color');
        box-shadow: dt('button.help.focus.ring.shadow');
    }

    .p-button-danger {
        background: dt('button.danger.background');
        border: 1px solid dt('button.danger.border.color');
        color: dt('button.danger.color');
    }

    .p-button-danger:not(:disabled):hover {
        background: dt('button.danger.hover.background');
        border: 1px solid dt('button.danger.hover.border.color');
        color: dt('button.danger.hover.color');
    }

    .p-button-danger:not(:disabled):active {
        background: dt('button.danger.active.background');
        border: 1px solid dt('button.danger.active.border.color');
        color: dt('button.danger.active.color');
    }

    .p-button-danger:focus-visible {
        outline-color: dt('button.danger.focus.ring.color');
        box-shadow: dt('button.danger.focus.ring.shadow');
    }

    .p-button-contrast {
        background: dt('button.contrast.background');
        border: 1px solid dt('button.contrast.border.color');
        color: dt('button.contrast.color');
    }

    .p-button-contrast:not(:disabled):hover {
        background: dt('button.contrast.hover.background');
        border: 1px solid dt('button.contrast.hover.border.color');
        color: dt('button.contrast.hover.color');
    }

    .p-button-contrast:not(:disabled):active {
        background: dt('button.contrast.active.background');
        border: 1px solid dt('button.contrast.active.border.color');
        color: dt('button.contrast.active.color');
    }

    .p-button-contrast:focus-visible {
        outline-color: dt('button.contrast.focus.ring.color');
        box-shadow: dt('button.contrast.focus.ring.shadow');
    }

    .p-button-outlined {
        background: transparent;
        border-color: dt('button.outlined.primary.border.color');
        color: dt('button.outlined.primary.color');
    }

    .p-button-outlined:not(:disabled):hover {
        background: dt('button.outlined.primary.hover.background');
        border-color: dt('button.outlined.primary.border.color');
        color: dt('button.outlined.primary.color');
    }

    .p-button-outlined:not(:disabled):active {
        background: dt('button.outlined.primary.active.background');
        border-color: dt('button.outlined.primary.border.color');
        color: dt('button.outlined.primary.color');
    }

    .p-button-outlined.p-button-secondary {
        border-color: dt('button.outlined.secondary.border.color');
        color: dt('button.outlined.secondary.color');
    }

    .p-button-outlined.p-button-secondary:not(:disabled):hover {
        background: dt('button.outlined.secondary.hover.background');
        border-color: dt('button.outlined.secondary.border.color');
        color: dt('button.outlined.secondary.color');
    }

    .p-button-outlined.p-button-secondary:not(:disabled):active {
        background: dt('button.outlined.secondary.active.background');
        border-color: dt('button.outlined.secondary.border.color');
        color: dt('button.outlined.secondary.color');
    }

    .p-button-outlined.p-button-success {
        border-color: dt('button.outlined.success.border.color');
        color: dt('button.outlined.success.color');
    }

    .p-button-outlined.p-button-success:not(:disabled):hover {
        background: dt('button.outlined.success.hover.background');
        border-color: dt('button.outlined.success.border.color');
        color: dt('button.outlined.success.color');
    }

    .p-button-outlined.p-button-success:not(:disabled):active {
        background: dt('button.outlined.success.active.background');
        border-color: dt('button.outlined.success.border.color');
        color: dt('button.outlined.success.color');
    }

    .p-button-outlined.p-button-info {
        border-color: dt('button.outlined.info.border.color');
        color: dt('button.outlined.info.color');
    }

    .p-button-outlined.p-button-info:not(:disabled):hover {
        background: dt('button.outlined.info.hover.background');
        border-color: dt('button.outlined.info.border.color');
        color: dt('button.outlined.info.color');
    }

    .p-button-outlined.p-button-info:not(:disabled):active {
        background: dt('button.outlined.info.active.background');
        border-color: dt('button.outlined.info.border.color');
        color: dt('button.outlined.info.color');
    }

    .p-button-outlined.p-button-warn {
        border-color: dt('button.outlined.warn.border.color');
        color: dt('button.outlined.warn.color');
    }

    .p-button-outlined.p-button-warn:not(:disabled):hover {
        background: dt('button.outlined.warn.hover.background');
        border-color: dt('button.outlined.warn.border.color');
        color: dt('button.outlined.warn.color');
    }

    .p-button-outlined.p-button-warn:not(:disabled):active {
        background: dt('button.outlined.warn.active.background');
        border-color: dt('button.outlined.warn.border.color');
        color: dt('button.outlined.warn.color');
    }

    .p-button-outlined.p-button-help {
        border-color: dt('button.outlined.help.border.color');
        color: dt('button.outlined.help.color');
    }

    .p-button-outlined.p-button-help:not(:disabled):hover {
        background: dt('button.outlined.help.hover.background');
        border-color: dt('button.outlined.help.border.color');
        color: dt('button.outlined.help.color');
    }

    .p-button-outlined.p-button-help:not(:disabled):active {
        background: dt('button.outlined.help.active.background');
        border-color: dt('button.outlined.help.border.color');
        color: dt('button.outlined.help.color');
    }

    .p-button-outlined.p-button-danger {
        border-color: dt('button.outlined.danger.border.color');
        color: dt('button.outlined.danger.color');
    }

    .p-button-outlined.p-button-danger:not(:disabled):hover {
        background: dt('button.outlined.danger.hover.background');
        border-color: dt('button.outlined.danger.border.color');
        color: dt('button.outlined.danger.color');
    }

    .p-button-outlined.p-button-danger:not(:disabled):active {
        background: dt('button.outlined.danger.active.background');
        border-color: dt('button.outlined.danger.border.color');
        color: dt('button.outlined.danger.color');
    }

    .p-button-outlined.p-button-contrast {
        border-color: dt('button.outlined.contrast.border.color');
        color: dt('button.outlined.contrast.color');
    }

    .p-button-outlined.p-button-contrast:not(:disabled):hover {
        background: dt('button.outlined.contrast.hover.background');
        border-color: dt('button.outlined.contrast.border.color');
        color: dt('button.outlined.contrast.color');
    }

    .p-button-outlined.p-button-contrast:not(:disabled):active {
        background: dt('button.outlined.contrast.active.background');
        border-color: dt('button.outlined.contrast.border.color');
        color: dt('button.outlined.contrast.color');
    }

    .p-button-outlined.p-button-plain {
        border-color: dt('button.outlined.plain.border.color');
        color: dt('button.outlined.plain.color');
    }

    .p-button-outlined.p-button-plain:not(:disabled):hover {
        background: dt('button.outlined.plain.hover.background');
        border-color: dt('button.outlined.plain.border.color');
        color: dt('button.outlined.plain.color');
    }

    .p-button-outlined.p-button-plain:not(:disabled):active {
        background: dt('button.outlined.plain.active.background');
        border-color: dt('button.outlined.plain.border.color');
        color: dt('button.outlined.plain.color');
    }

    .p-button-text {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.primary.color');
    }

    .p-button-text:not(:disabled):hover {
        background: dt('button.text.primary.hover.background');
        border-color: transparent;
        color: dt('button.text.primary.color');
    }

    .p-button-text:not(:disabled):active {
        background: dt('button.text.primary.active.background');
        border-color: transparent;
        color: dt('button.text.primary.color');
    }

    .p-button-text.p-button-secondary {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.secondary.color');
    }

    .p-button-text.p-button-secondary:not(:disabled):hover {
        background: dt('button.text.secondary.hover.background');
        border-color: transparent;
        color: dt('button.text.secondary.color');
    }

    .p-button-text.p-button-secondary:not(:disabled):active {
        background: dt('button.text.secondary.active.background');
        border-color: transparent;
        color: dt('button.text.secondary.color');
    }

    .p-button-text.p-button-success {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.success.color');
    }

    .p-button-text.p-button-success:not(:disabled):hover {
        background: dt('button.text.success.hover.background');
        border-color: transparent;
        color: dt('button.text.success.color');
    }

    .p-button-text.p-button-success:not(:disabled):active {
        background: dt('button.text.success.active.background');
        border-color: transparent;
        color: dt('button.text.success.color');
    }

    .p-button-text.p-button-info {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.info.color');
    }

    .p-button-text.p-button-info:not(:disabled):hover {
        background: dt('button.text.info.hover.background');
        border-color: transparent;
        color: dt('button.text.info.color');
    }

    .p-button-text.p-button-info:not(:disabled):active {
        background: dt('button.text.info.active.background');
        border-color: transparent;
        color: dt('button.text.info.color');
    }

    .p-button-text.p-button-warn {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.warn.color');
    }

    .p-button-text.p-button-warn:not(:disabled):hover {
        background: dt('button.text.warn.hover.background');
        border-color: transparent;
        color: dt('button.text.warn.color');
    }

    .p-button-text.p-button-warn:not(:disabled):active {
        background: dt('button.text.warn.active.background');
        border-color: transparent;
        color: dt('button.text.warn.color');
    }

    .p-button-text.p-button-help {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.help.color');
    }

    .p-button-text.p-button-help:not(:disabled):hover {
        background: dt('button.text.help.hover.background');
        border-color: transparent;
        color: dt('button.text.help.color');
    }

    .p-button-text.p-button-help:not(:disabled):active {
        background: dt('button.text.help.active.background');
        border-color: transparent;
        color: dt('button.text.help.color');
    }

    .p-button-text.p-button-danger {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.danger.color');
    }

    .p-button-text.p-button-danger:not(:disabled):hover {
        background: dt('button.text.danger.hover.background');
        border-color: transparent;
        color: dt('button.text.danger.color');
    }

    .p-button-text.p-button-danger:not(:disabled):active {
        background: dt('button.text.danger.active.background');
        border-color: transparent;
        color: dt('button.text.danger.color');
    }

    .p-button-text.p-button-contrast {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.contrast.color');
    }

    .p-button-text.p-button-contrast:not(:disabled):hover {
        background: dt('button.text.contrast.hover.background');
        border-color: transparent;
        color: dt('button.text.contrast.color');
    }

    .p-button-text.p-button-contrast:not(:disabled):active {
        background: dt('button.text.contrast.active.background');
        border-color: transparent;
        color: dt('button.text.contrast.color');
    }

    .p-button-text.p-button-plain {
        background: transparent;
        border-color: transparent;
        color: dt('button.text.plain.color');
    }

    .p-button-text.p-button-plain:not(:disabled):hover {
        background: dt('button.text.plain.hover.background');
        border-color: transparent;
        color: dt('button.text.plain.color');
    }

    .p-button-text.p-button-plain:not(:disabled):active {
        background: dt('button.text.plain.active.background');
        border-color: transparent;
        color: dt('button.text.plain.color');
    }

    .p-button-link {
        background: transparent;
        border-color: transparent;
        color: dt('button.link.color');
    }

    .p-button-link:not(:disabled):hover {
        background: transparent;
        border-color: transparent;
        color: dt('button.link.hover.color');
    }

    .p-button-link:not(:disabled):hover .p-button-label {
        text-decoration: underline;
    }

    .p-button-link:not(:disabled):active {
        background: transparent;
        border-color: transparent;
        color: dt('button.link.active.color');
    }
`;function ct(e){"@babel/helpers - typeof";return ct=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ct(e)}function ve(e,t,n){return(t=Ia(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Ia(e){var t=Da(e,"string");return ct(t)=="symbol"?t:t+""}function Da(e,t){if(ct(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ct(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Ra={root:function(t){var n=t.instance,o=t.props;return["p-button p-component",ve(ve(ve(ve(ve(ve(ve(ve(ve({"p-button-icon-only":n.hasIcon&&!o.label&&!o.badge,"p-button-vertical":(o.iconPos==="top"||o.iconPos==="bottom")&&o.label,"p-button-loading":o.loading,"p-button-link":o.link||o.variant==="link"},"p-button-".concat(o.severity),o.severity),"p-button-raised",o.raised),"p-button-rounded",o.rounded),"p-button-text",o.text||o.variant==="text"),"p-button-outlined",o.outlined||o.variant==="outlined"),"p-button-sm",o.size==="small"),"p-button-lg",o.size==="large"),"p-button-plain",o.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(t){var n=t.props;return["p-button-icon",ve({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},Va=R.extend({name:"button",style:ja,classes:Ra}),Ma={name:"BaseButton",extends:nn,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:Va,provide:function(){return{$pcButton:this,$parentInstance:this}}};function pt(e){"@babel/helpers - typeof";return pt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},pt(e)}function J(e,t,n){return(t=Ba(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Ba(e){var t=Wa(e,"string");return pt(t)=="symbol"?t:t+""}function Wa(e,t){if(pt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(pt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var We={name:"Button",extends:Ma,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(t){var n=t==="root"?this.ptmi:this.ptm;return n(t,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return X(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return Ne(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return Ze(J(J(J(J(J(J(J(J(J(J({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return Ze(J(J({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return Ze(J(J({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:io,Badge:so},directives:{ripple:Na}},Ua=["data-p"],za=["data-p"];function Ha(e,t,n,o,r,a){var s=zt("SpinnerIcon"),l=zt("Badge"),i=Po("ripple");return e.asChild?Fe(e.$slots,"default",{key:1,class:Ce(e.cx("root")),a11yAttrs:a.a11yAttrs}):xo((O(),Me(Oo(e.as),X({key:0,class:e.cx("root"),"data-p":a.dataP},a.attrs),{default:Be(function(){return[Fe(e.$slots,"default",{},function(){return[e.loading?Fe(e.$slots,"loadingicon",X({key:0,class:[e.cx("loadingIcon"),e.cx("icon")]},e.ptm("loadingIcon")),function(){return[e.loadingIcon?(O(),L("span",X({key:0,class:[e.cx("loadingIcon"),e.cx("icon"),e.loadingIcon]},e.ptm("loadingIcon")),null,16)):(O(),Me(s,X({key:1,class:[e.cx("loadingIcon"),e.cx("icon")],spin:""},e.ptm("loadingIcon")),null,16,["class"]))]}):Fe(e.$slots,"icon",X({key:1,class:[e.cx("icon")]},e.ptm("icon")),function(){return[e.icon?(O(),L("span",X({key:0,class:[e.cx("icon"),e.icon,e.iconClass],"data-p":a.dataIconP},e.ptm("icon")),null,16,Ua)):F("",!0)]}),e.label?(O(),L("span",X({key:2,class:e.cx("label")},e.ptm("label"),{"data-p":a.dataLabelP}),ee(e.label),17,za)):F("",!0),e.badge?(O(),Me(l,{key:3,value:e.badge,class:Ce(e.badgeClass),severity:e.badgeSeverity,unstyled:e.unstyled,pt:e.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):F("",!0)]})]}),_:3},16,["class","data-p"])),[[i]])}We.render=Ha;const lo=Symbol("host_api"),uo=Symbol("axios"),co=Symbol("proxy"),po=Symbol("config"),qa=Symbol("on_subscription");function Ka(){const e=Tt(lo);if(!e)throw new Error("HostApi not provided");return e}function Fa(){const e=Tt(uo);if(!e)throw new Error("ProxyApiInstance not provided");return e}function Ga(){const e=Tt(co);if(!e)throw new Error("WIPPY_INSTANCE not provided");return e}function Ya(){const e=Tt(po);if(!e)throw new Error("WippyConfig not provided");return e}const ps={changeset:"keeper.changeset",git:"keeper.git",version:"registry:version"};async function Qa(e){const{data:t}=await e.post("/api/v1/keeper/events/subscribe",{});return t}async function Za(e){const{data:t}=await e.post("/api/v1/keeper/events/unsubscribe",{});return t}const on="keeper.events.muted",Ue=M(!1),At=M(localStorage.getItem(on)==="1"),$t=M(!1),mt=M(null);function mo(e){return e?.response?.data?.error||e?.message||"request failed"}async function fo(e,t=!1){if(!(At.value||$t.value)&&!(Ue.value&&!t)){$t.value=!0;try{const n=await Qa(e);Ue.value=n.subscribed===!0,mt.value=null}catch(n){Ue.value=!1,mt.value=mo(n)}finally{$t.value=!1}}}async function Ja(e){if(At.value=!0,localStorage.setItem(on,"1"),!!Ue.value)try{await Za(e),Ue.value=!1,mt.value=null}catch(t){mt.value=mo(t)}}async function Xa(e){At.value=!1,localStorage.removeItem(on),await fo(e,!0)}function ei(){return{subscribed:Ue,muted:At,pending:$t,error:mt,ensureSubscribed:fo,mute:Ja,unmute:Xa}}async function ms(e){const{data:t}=await e.get("/api/v1/keeper/registry/namespaces");return t}async function fs(e,t={}){const n={limit:t.limit||200,offset:t.offset||0};t.namespace&&(n.namespace=t.namespace),t.kind&&(n.kind=t.kind),t.metaType&&(n["meta.type"]=t.metaType),t.query&&(n.q=t.query);const{data:o}=await e.get("/api/v1/keeper/registry/entries",{params:n});return o}async function bs(e,t){const{data:n}=await e.get("/api/v1/keeper/registry/entry",{params:{id:t}});return n}async function vs(e,t,n){const{data:o}=await e.put("/api/v1/keeper/registry/entry",n,{params:{id:t}});return o}async function gs(e,t){const n={};t&&(n.namespace=t);const{data:o}=await e.get("/api/v1/keeper/state/graph",{params:n});return o}async function hs(e){const{data:t}=await e.get("/api/v1/keeper/env/list");return t}async function ys(e,t,n){const{data:o}=await e.post("/api/v1/keeper/env/set",{key:t,value:n});return o}async function Ss(e){const{data:t}=await e.get("/api/v1/keeper/sync/state");return t}async function _s(e){const{data:t}=await e.get("/api/v1/keeper/sync/config");return t}async function ws(e,t){const{data:n}=await e.put("/api/v1/keeper/sync/config",{managed_namespaces:t});return n}async function $s(e){const{data:t}=await e.post("/api/v1/keeper/sync/download");return t}async function ks(e){const{data:t}=await e.post("/api/v1/keeper/sync/upload");return t}async function Ps(e){const{data:t}=await e.post("/api/v1/keeper/sync/undo");return t}async function xs(e){const{data:t}=await e.post("/api/v1/keeper/sync/redo");return t}const Wt={"ns.definition":"var(--p-info-500)","ns.requirement":"var(--p-warn-500)","ns.dependency":"var(--p-accent-400)","http.service":"var(--p-success-500)","http.router":"var(--p-success-500)","http.endpoint":"var(--p-info-500)","http.static":"var(--p-info-500)","function.lua":"var(--p-warn-500)","library.lua":"var(--p-warn-500)","process.lua":"var(--p-warn-500)","registry.entry":"var(--p-accent-500)","db.sql.sqlite":"var(--p-accent-500)","fs.directory":"var(--p-text-muted-color)","fs.embed":"var(--p-text-muted-color)","process.host":"var(--p-info-500)","store.memory":"var(--p-accent-500)","store.sql":"var(--p-accent-500)","env.variable":"var(--p-text-muted-color)","env.composite":"var(--p-text-muted-color)","env.file":"var(--p-text-muted-color)","env.os":"var(--p-text-muted-color)","env.memory":"var(--p-text-muted-color)","security.policy":"var(--p-danger-500)","view.page":"var(--p-info-500)","view.component":"var(--p-info-500)","queue.memory":"var(--p-accent-500)","queue.consumer":"var(--p-accent-500)","template.set":"var(--p-warn-500)",contract:"var(--p-accent-400)","agent.gen1":"var(--p-warn-500)","agent.trait":"var(--p-warn-500)","llm.model":"var(--p-accent-500)",tool:"var(--p-info-500)"},Ut={"ns.definition":"tabler:package","ns.requirement":"tabler:plug","ns.dependency":"tabler:link","http.service":"tabler:server","http.router":"tabler:route","http.endpoint":"tabler:api","http.static":"tabler:file","function.lua":"tabler:code","library.lua":"tabler:book","process.lua":"tabler:code","registry.entry":"tabler:database","db.sql.sqlite":"tabler:database","fs.directory":"tabler:folder","fs.embed":"tabler:folder","process.host":"tabler:cpu","store.memory":"tabler:database","store.sql":"tabler:database","env.variable":"tabler:variable","env.composite":"tabler:variable","env.file":"tabler:variable","env.os":"tabler:variable","env.memory":"tabler:variable","security.policy":"tabler:shield-check","view.page":"tabler:browser","view.component":"tabler:components","queue.memory":"tabler:list","queue.consumer":"tabler:player-play","template.set":"tabler:template",contract:"tabler:file-certificate","agent.gen1":"tabler:robot","agent.trait":"tabler:sparkles","llm.model":"tabler:brain",tool:"tabler:tool"};function kt(e,t){return t&&Wt[t]?Wt[t]:Wt[e]||"var(--p-text-muted-color)"}function bo(e,t){return t&&Ut[t]?Ut[t]:Ut[e]||"tabler:circle"}async function Os(e,t=100,n=0){const{data:o}=await e.get("/api/v1/sessions",{params:{limit:t,offset:n}});return o}async function Ts(e,t){const{data:n}=await e.get("/api/v1/sessions/get",{params:{session_id:t}});return n}async function Cs(e,t,n=50,o=""){const{data:r}=await e.get("/api/v1/sessions/messages",{params:{session_id:t,limit:n,cursor:o}});return r}function As(e){return!e||e===0?"0":e>=1e6?(e/1e6).toFixed(1)+"M":e>=1e3?(e/1e3).toFixed(1)+"K":e.toString()}function Dn(e){if(!e)return"";let t;typeof e=="number"?e>1e15?t=e/1e6:e>1e12?t=e/1e3:e>1e10?t=e:t=e*1e3:t=new Date(e).getTime();const n=new Date(t);if(isNaN(n.getTime()))return"";const r=Math.floor((new Date().getTime()-n.getTime())/1e3);if(r<60)return"just now";const a=Math.floor(r/60);if(a<60)return`${a}m ago`;const s=Math.floor(a/60);if(s<24)return`${s}h ago`;const l=Math.floor(s/24);if(l<30)return`${l}d ago`;const i=Math.floor(l/30);return i<12?`${i}mo ago`:`${Math.floor(i/12)}y ago`}function Es(e){return e?new Date(typeof e=="number"?e*1e3:e).toLocaleString():"N/A"}const ti={key:0,class:"status-dropdown"},ni=["onClick"],oi={key:0,class:"plugin-tag",title:"Provided by a registered plugin"},ri=Le({__name:"AppNavDropdown",props:{icon:{},label:{},items:{},open:{type:Boolean},active:{type:Boolean},currentName:{},wrapClass:{}},emits:["toggle","navigate"],setup(e,{emit:t}){const n=t;function o(r){n("navigate",r)}return(r,a)=>(O(),L("div",{class:Ce(["relative",e.wrapClass])},[I(A(We),{variant:"text",class:Ce(["k-btn-nav relative !gap-1.5",{"k-btn-active":e.active}]),onClick:a[0]||(a[0]=s=>n("toggle"))},{default:Be(()=>[I(A(K),{icon:e.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Xe(" "+ee(e.label)+" ",1),I(A(K),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.5"}})]),_:1},8,["class"]),e.open?(O(),L("div",ti,[(O(!0),L(et,null,tt(e.items,s=>(O(),L("button",{key:s.name,class:Ce(["status-item",{"status-item--active":e.currentName===s.name}]),onClick:l=>o(s.path)},[I(A(K),{icon:s.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Xe(" "+ee(s.label)+" ",1),s.name.startsWith("plugin:")?(O(),L("span",oi,"plugin")):F("",!0)],10,ni))),128))])):F("",!0)],2))}}),rn=(e,t)=>{const n=e.__vccOpts||e;for(const[o,r]of t)n[o]=r;return n},Ke=rn(ri,[["__scopeId","data-v-6d403115"]]),ai={class:"truncate",style:{"max-width":"80px"}},ii={key:1,class:"relative agent-dropdown-wrap"},si={key:0,class:"agent-dropdown"},li=["onClick"],ui={class:"agent-item-copy"},di={class:"agent-item-title"},ci={key:0,class:"agent-item-comment"},pi=Le({__name:"AppAgentLauncher",props:{agents:{},open:{type:Boolean}},emits:["toggle","start"],setup(e,{emit:t}){const n=t;return(o,r)=>e.agents.length===1?(O(),L("button",{key:0,class:"ask-btn",onClick:r[0]||(r[0]=a=>n("start",e.agents[0].start_token))},[I(A(K),{icon:e.agents[0].icon||"tabler:message-bolt",class:"w-3.5 h-3.5"},null,8,["icon"]),W("span",ai,ee(e.agents[0].title||"Ask"),1)])):e.agents.length>1?(O(),L("div",ii,[W("button",{class:"ask-btn",onClick:r[1]||(r[1]=a=>n("toggle"))},[I(A(K),{icon:"tabler:message-bolt",class:"w-3.5 h-3.5"}),r[2]||(r[2]=Xe(" Ask ",-1)),I(A(K),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.6"}})]),e.open?(O(),L("div",si,[(O(!0),L(et,null,tt(e.agents,a=>(O(),L("button",{key:a.id,class:"agent-item",onClick:s=>n("start",a.start_token)},[I(A(K),{icon:a.icon||"tabler:robot",class:"agent-item-icon"},null,8,["icon"]),W("span",ui,[W("span",di,ee(a.title||a.id),1),a.comment?(O(),L("span",ci,ee(a.comment),1)):F("",!0)])],8,li))),128))])):F("",!0)])):F("",!0)}}),mi=rn(pi,[["__scopeId","data-v-eeb14e8e"]]),fi={key:0,class:"flex items-center gap-1.5 text-xs pl-2",style:{color:"var(--p-text-muted-color)","border-left":"1px solid var(--p-content-border-color)"}},bi={class:"truncate max-w-[100px]"},vi=Le({__name:"AppUserChip",props:{user:{}},emits:["logout"],setup(e,{emit:t}){const n=t;return(o,r)=>e.user?(O(),L("div",fi,[W("span",bi,ee(e.user.full_name||e.user.email),1),I(A(We),{class:"k-btn-icon !w-6 !h-6 !p-0 !rounded-full",title:"Logout",onClick:r[0]||(r[0]=a=>n("logout"))},{default:Be(()=>[I(A(K),{icon:"tabler:logout",class:"w-3 h-3"})]),_:1})])):F("",!0)}}),gi={class:"search-modal"},hi={class:"search-header"},yi=["value"],Si={key:0,class:"search-results"},_i=["onClick"],wi={class:"flex-1 min-w-0"},$i={class:"text-[11px] font-mono truncate",style:{color:"var(--p-text-color)"}},ki={key:0,class:"text-[9px] truncate",style:{color:"var(--p-text-muted-color)"}},Pi={key:1,class:"search-empty"},xi={key:2,class:"search-hints"},Oi=["onClick"],Ti={class:"text-[10px] font-mono",style:{color:"var(--p-primary-color)"}},Ci={class:"text-[10px]",style:{color:"var(--p-text-muted-color)"}},Ai=Le({__name:"AppGlobalSearch",props:{open:{type:Boolean},query:{},results:{},loading:{type:Boolean},hints:{}},emits:["update:query","close","search-input","select","apply-hint"],setup(e,{emit:t}){const n=t;function o(r){r.length>0&&n("select",r[0])}return(r,a)=>(O(),Me(To,{to:"body"},[e.open?(O(),L("div",{key:0,class:"search-overlay",onClick:a[3]||(a[3]=Co(s=>n("close"),["self"]))},[W("div",gi,[W("div",hi,[I(A(K),{icon:"tabler:search",class:"w-4 h-4 shrink-0",style:{color:"var(--p-text-muted-color)"}}),W("input",{value:e.query,onInput:a[0]||(a[0]=s=>{n("update:query",s.target.value),n("search-input")}),onKeydown:[a[1]||(a[1]=un(s=>n("close"),["escape"])),a[2]||(a[2]=un(s=>o(e.results),["enter"]))],class:"global-search-input",placeholder:"Search entries, functions, configs...",autofocus:""},null,40,yi),e.loading?(O(),Me(A(K),{key:0,icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin",style:{color:"var(--p-primary-color)"}})):F("",!0),a[4]||(a[4]=W("kbd",{class:"search-kbd"},"Esc",-1))]),e.results.length>0?(O(),L("div",Si,[(O(!0),L(et,null,tt(e.results,s=>(O(),L("div",{key:s.id,class:"search-item",onClick:l=>n("select",s)},[I(A(K),{icon:s.icon||A(bo)(s.kind),class:"w-3 h-3 shrink-0",style:Ht({color:s.color||A(kt)(s.kind)})},null,8,["icon","style"]),W("div",wi,[W("div",$i,ee(s.id),1),s.snippet?(O(),L("div",ki,ee(s.snippet),1)):F("",!0)]),W("span",{class:"text-[8px] px-1 rounded",style:Ht({color:s.color||A(kt)(s.kind),background:`color-mix(in srgb, ${s.color||A(kt)(s.kind)} 12%, transparent)`})},ee(s.kind),5)],8,_i))),128))])):e.query&&!e.loading?(O(),L("div",Pi,"No results")):e.query?F("",!0):(O(),L("div",xi,[(O(!0),L(et,null,tt(e.hints,s=>(O(),L("div",{key:s.prefix,class:"search-hint",onClick:l=>n("apply-hint",s.prefix)},[I(A(K),{icon:s.icon,class:"w-3 h-3 shrink-0",style:{color:"var(--p-text-muted-color)"}},null,8,["icon"]),W("span",Ti,ee(s.prefix||"*"),1),W("span",Ci,ee(s.desc),1)],8,Oi))),128))]))])])):F("",!0)]))}}),Ei={class:"h-full flex flex-col"},Li={class:"shrink-0 h-10 flex items-center px-3 gap-3",style:{background:"var(--p-content-background)","border-bottom":"1px solid var(--p-content-border-color)"}},Ni={class:"flex items-center gap-0.5 flex-1"},ji={class:"flex items-center gap-1.5 shrink-0"},Ii={key:0,class:"activity-live"},Di={class:"flex-1 overflow-y-auto",style:{background:"color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)"}},Ri=Le({__name:"app",setup(e){const t=Mn(),n=Lo(),o=Fa(),r=Ya(),a=Ka(),s=Ga(),l=ei(),i=l.subscribed,u=l.muted,d=M(0),c=M(0);let p=null,m=null,f=null;async function y(){try{const{data:b}=await o.get("/api/v1/keeper/logger/stats");b.success&&b.stats?.counters&&(d.value=b.stats.counters.error||0,c.value=b.stats.counters.warn||0)}catch{}}const g=[{path:"/",name:"dashboard",label:"Home",icon:"tabler:layout-dashboard"}],S=[{path:"/settings/environment",name:"settings-environment",label:"Environment",icon:"tabler:variable"},{path:"/settings/registry",name:"settings-registry",label:"Registry",icon:"tabler:database"},{path:"/settings/hub",name:"settings-hub",label:"Wippy Hub",icon:"tabler:cloud"},{path:"/mcp",name:"mcp",label:"MCP",icon:"tabler:plug-connected"}],$=[{path:"/sessions",name:"sessions",label:"Sessions",icon:"tabler:list"},{path:"/dataflows",name:"workflow",label:"Dataflows",icon:"tabler:git-merge"},{path:"/system",name:"system",label:"System",icon:"tabler:activity"},{path:"/logs",name:"logs",label:"Logs",icon:"tabler:file-text"}],j=[],v=[{path:"/structure",name:"structure",label:"Registry",icon:"tabler:binary-tree"},{path:"/agents",name:"agents",label:"Agents",icon:"tabler:robot"},{path:"/models",name:"models",label:"Models",icon:"tabler:brain"},{path:"/tools",name:"tools",label:"Tools",icon:"tabler:tool"},{path:"/traits",name:"traits",label:"Traits",icon:"tabler:sparkles"},{path:"/endpoints",name:"endpoints",label:"Endpoints",icon:"tabler:api"},{path:"/policies",name:"policies",label:"Policies",icon:"tabler:shield-check"}],k=[{path:"/tasks",name:"tasks",label:"Pipeline",icon:"tabler:git-merge"},{path:"/changes",name:"changes",label:"Changes",icon:"tabler:git-branch"},{path:"/components",name:"components",label:"Components",icon:"tabler:puzzle"},{path:"/knowledge",name:"knowledge",label:"Knowledge",icon:"tabler:brain"},{path:"/tests",name:"tests",label:"Tests",icon:"tabler:test-pipe"}],V=M([]);async function G(){try{const b=r.apiRoutes?.pages,_=b?.["@prefix"]??"/api/public/pages",Z=b?.list??"@/list",P=Z.startsWith("@/")?_.replace(/\/$/,"")+Z.slice(1):Z,{data:U}=await o.get(P);if(!U?.success||!Array.isArray(U.pages))return;V.value=U.pages.filter(C=>C.announced&&C.id.startsWith("keeper.")&&C.id!=="keeper:main").sort((C,h)=>(C.order||9999)-(h.order||9999)||C.title.localeCompare(h.title)).map(C=>({path:`/plugin/${C.id}`,name:`plugin:${C.id}`,label:C.title||C.name,icon:C.icon||"tabler:puzzle",group:C.group||"develop"}))}catch{}}const de=q(()=>[...$,...V.value.filter(b=>b.group==="observe")]),ce=q(()=>[...v,...V.value.filter(b=>b.group==="structure")]),be=q(()=>[...k,...V.value.filter(b=>b.group==="develop"||!b.group)]),se=q(()=>[...j,...V.value.filter(b=>b.group==="status")]),ne=M(!1),oe=M(!1),Y=M(!1),re=M(!1),le=M(!1),Q=M(!1),_e=q(()=>new Set(se.value.map(b=>b.name))),we=q(()=>new Set(ce.value.map(b=>b.name))),pe=q(()=>new Set(be.value.map(b=>b.name))),ue=q(()=>new Set(de.value.map(b=>b.name))),ye=q(()=>new Set(S.map(b=>b.name))),B=q(()=>n.name),$e=q(()=>_e.value.has(String(B.value))),ft=q(()=>we.value.has(String(B.value))),bt=q(()=>pe.value.has(String(B.value))),Et=q(()=>ue.value.has(String(B.value))||B.value==="session-detail"||B.value==="dataflow-detail"),Lt=q(()=>ye.value.has(String(B.value))||B.value==="settings"),vt=M(null);function Ie(b){t.push(b)}function Nt(){ne.value=!1,oe.value=!1,Y.value=!1,re.value=!1,le.value=!1,Q.value=!1}function Oe(b){Ie(b),Nt()}async function jt(){try{const{data:b}=await o.get("/api/v1/user/me");b.success&&b.user&&(vt.value={email:b.user.email,full_name:b.user.full_name})}catch{}}const gt=M([]);async function It(){try{const{data:b}=await o.get("/api/v1/keeper/agents/list",{params:{public_only:!0}});gt.value=b.agents||[]}catch{}}function Dt(b){a.startChat(b,{sidebar:!0}),Q.value=!1}const ke=M(!1),Te=M(""),ae=M([]),ze=M(!1);let He=null;const Rt=[{prefix:"session:",desc:"Search sessions by title or ID",icon:"tabler:list"},{prefix:"dataflow:",desc:"Search dataflows",icon:"tabler:git-merge"},{prefix:"agent:",desc:"Search agents",icon:"tabler:robot"},{prefix:"model:",desc:"Search LLM models",icon:"tabler:brain"},{prefix:"tool:",desc:"Search tools",icon:"tabler:tool"},{prefix:"endpoint:",desc:"Search HTTP endpoints",icon:"tabler:api"},{prefix:"",desc:"Search all registry entries",icon:"tabler:search"}];async function ht(){const b=Te.value.trim();if(!b){ae.value=[];return}ze.value=!0;try{const _=b.indexOf(":"),Z=_>0?b.slice(0,_).toLowerCase():"",P=_>0?b.slice(_+1).trim():b;if(Z==="session"){const{data:U}=await o.get("/api/v1/sessions",{params:{limit:20}}),C=(U.sessions||[]).filter(h=>!P||h.title?.toLowerCase().includes(P.toLowerCase())||h.session_id?.includes(P)||h.current_agent?.toLowerCase().includes(P.toLowerCase()));ae.value=C.slice(0,15).map(h=>({id:h.title||h.session_id?.slice(0,12)+"...",kind:h.current_agent||"session",snippet:[h.current_model,h.status,Dn(h.last_message_date||h.start_date)].filter(Boolean).join(" · "),icon:"tabler:message",color:"var(--p-info-500)",route:"/session/"+h.session_id}))}else if(Z==="dataflow"){const{data:U}=await o.get("/api/v1/dataflows",{params:{limit:20}}),C=(U.dataflows||[]).filter(h=>!P||h.metadata?.title?.toLowerCase().includes(P.toLowerCase())||h.dataflow_id?.includes(P));ae.value=C.slice(0,15).map(h=>({id:h.metadata?.title||h.dataflow_id?.slice(0,12)+"...",kind:h.status||"dataflow",snippet:[h.type,Dn(h.created_at)].filter(Boolean).join(" · "),icon:"tabler:git-merge",color:h.status==="running"?"var(--p-success-500)":h.status==="failed"?"var(--p-danger-500)":"var(--p-info-500)",route:"/dataflow/"+h.dataflow_id}))}else if(Z==="agent"){const{data:U}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"agent.gen1",limit:100}}),C=(U.entries||[]).filter(h=>!P||h.id.toLowerCase().includes(P.toLowerCase())||h.meta?.title?.toLowerCase().includes(P.toLowerCase()));ae.value=C.slice(0,15).map(h=>({id:h.id,kind:h.kind,snippet:h.meta?.title||"",icon:"tabler:robot",color:"var(--p-warn-500)",route:"/structure?entry="+h.id}))}else if(Z==="model"){const{data:U}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"llm.model",limit:100}}),C=(U.entries||[]).filter(h=>!P||h.id.toLowerCase().includes(P.toLowerCase())||h.meta?.title?.toLowerCase().includes(P.toLowerCase()));ae.value=C.slice(0,15).map(h=>({id:h.id,kind:h.kind,snippet:h.meta?.title||"",icon:"tabler:brain",color:"var(--p-accent-500)",route:"/structure?entry="+h.id}))}else if(Z==="tool"){const{data:U}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"tool",limit:100}}),C=(U.entries||[]).filter(h=>!P||h.id.toLowerCase().includes(P.toLowerCase())||h.meta?.title?.toLowerCase().includes(P.toLowerCase()));ae.value=C.slice(0,15).map(h=>({id:h.id,kind:h.kind,snippet:h.meta?.comment||h.meta?.llm_alias||"",icon:"tabler:tool",color:"var(--p-info-500)",route:"/structure?entry="+h.id}))}else if(Z==="endpoint"){const{data:U}=await o.get("/api/v1/keeper/registry/entries",{params:{kind:"http.endpoint",limit:200}}),C=(U.entries||[]).filter(h=>!P||h.id.toLowerCase().includes(P.toLowerCase()));ae.value=C.slice(0,15).map(h=>({id:h.id,kind:h.kind,snippet:h.meta?.comment||"",icon:"tabler:api",color:"var(--p-info-500)",route:"/structure?entry="+h.id}))}else{const{data:U}=await o.get("/api/v1/keeper/state/search",{params:{q:b,limit:30}});ae.value=(U.results||[]).map(C=>({id:C.id,kind:C.kind,snippet:C.snippet,icon:bo(C.kind),color:kt(C.kind),route:"/structure?entry="+C.id}))}}catch{ae.value=[]}finally{ze.value=!1}}function Vt(){He&&clearTimeout(He),He=window.setTimeout(ht,300)}function vo(b){Te.value=b,ht(),window.setTimeout(()=>{const _=document.querySelector(".global-search-input");_&&(_.focus(),_.setSelectionRange(b.length,b.length))},10)}function go(b){if(ke.value=!1,Te.value="",ae.value=[],b.route)if(b.route.includes("?")){const[_,Z]=b.route.split("?"),P=Object.fromEntries(new URLSearchParams(Z));t.push({path:_,query:P})}else t.push(b.route)}function an(b){(b.ctrlKey||b.metaKey)&&b.shiftKey&&(b.key==="F"||b.key==="f")&&(b.preventDefault(),ke.value=!0,setTimeout(()=>document.querySelector(".global-search-input")?.focus(),50)),b.key==="Escape"&&ke.value&&(ke.value=!1)}function ho(){a.logout()}Re(()=>n.fullPath,()=>{try{const b={page:n.name,path:n.fullPath};n.query.entry&&(b.selected_entry=n.query.entry),n.query.ns&&(b.namespace=n.query.ns),a.setContext(b)}catch{}});function sn(b){const _=b.target;_.closest(".status-dropdown-wrap")||(ne.value=!1),_.closest(".structure-dropdown-wrap")||(oe.value=!1),_.closest(".develop-dropdown-wrap")||(Y.value=!1),_.closest(".observe-dropdown-wrap")||(re.value=!1),_.closest(".settings-dropdown-wrap")||(le.value=!1),_.closest(".agent-dropdown-wrap")||(Q.value=!1)}return Vn(()=>{p=s.on("action:navigate",b=>{const _=b?.data?.path||b?.path;_&&t.push(_)}),m=s.on("keeper.logs",b=>{const _=b?.data?.counters||b?.counters;_&&(d.value=_.error||0,c.value=_.warn||0)}),f=s.on("welcome",()=>l.ensureSubscribed(o,!0)),jt(),y(),It(),G(),l.ensureSubscribed(o,!0),document.addEventListener("click",sn),document.addEventListener("keydown",an)}),Ao(()=>{f?.(),p?.(),m?.(),document.removeEventListener("click",sn),document.removeEventListener("keydown",an)}),(b,_)=>{const Z=zt("router-view");return O(),L("div",Ei,[W("header",Li,[I(A(We),{variant:"text",class:"shrink-0 !gap-1.5",onClick:_[0]||(_[0]=P=>Ie("/"))},{default:Be(()=>[I(A(K),{icon:"tabler:shield-code",class:"w-4 h-4"}),_[10]||(_[10]=W("span",{class:"text-xs font-bold tracking-wider font-mono"},"KEEPER",-1))]),_:1}),W("nav",Ni,[(O(),L(et,null,tt(g,P=>I(A(We),{key:P.name,variant:"text",class:Ce(["k-btn-nav relative !gap-1.5",{"k-btn-active":B.value===P.name}]),onClick:U=>Ie(P.path)},{default:Be(()=>[I(A(K),{icon:P.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Xe(" "+ee(P.label),1)]),_:2},1032,["class","onClick"])),64)),I(Ke,{icon:"tabler:eye",label:"Observe","wrap-class":"observe-dropdown-wrap",items:de.value,open:re.value,active:Et.value,"current-name":B.value,onToggle:_[1]||(_[1]=P=>re.value=!re.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),I(Ke,{icon:"tabler:binary-tree",label:"Structure","wrap-class":"structure-dropdown-wrap",items:ce.value,open:oe.value,active:ft.value,"current-name":B.value,onToggle:_[2]||(_[2]=P=>oe.value=!oe.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),I(Ke,{icon:"tabler:code",label:"Develop","wrap-class":"develop-dropdown-wrap",items:be.value,open:Y.value,active:bt.value,"current-name":B.value,onToggle:_[3]||(_[3]=P=>Y.value=!Y.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),se.value.length?(O(),Me(Ke,{key:0,icon:"tabler:heart-rate-monitor",label:"Status","wrap-class":"status-dropdown-wrap",items:se.value,open:ne.value,active:$e.value,"current-name":B.value,onToggle:_[4]||(_[4]=P=>ne.value=!ne.value),onNavigate:Oe},null,8,["items","open","active","current-name"])):F("",!0),I(Ke,{icon:"tabler:settings",label:"Settings","wrap-class":"settings-dropdown-wrap",items:S,open:le.value,active:Lt.value,"current-name":B.value,onToggle:_[5]||(_[5]=P=>le.value=!le.value),onNavigate:Oe},null,8,["open","active","current-name"])]),W("div",ji,[I(A(We),{variant:"text",class:Ce(["k-btn-icon !rounded relative",{"k-btn-active":B.value==="activity"}]),title:A(u)?"Admin activity — muted":A(i)?"Admin activity — live":"Admin activity",onClick:_[6]||(_[6]=P=>Ie("/activity"))},{default:Be(()=>[I(A(K),{icon:A(u)?"tabler:broadcast-off":"tabler:broadcast",class:"w-4 h-4",style:Ht({color:A(i)&&!A(u)?"var(--p-primary-color)":"var(--p-text-muted-color)"})},null,8,["icon","style"]),A(i)&&!A(u)?(O(),L("span",Ii)):F("",!0)]),_:1},8,["class","title"]),I(mi,{agents:gt.value,open:Q.value,onToggle:_[7]||(_[7]=P=>Q.value=!Q.value),onStart:Dt},null,8,["agents","open"]),I(vi,{user:vt.value,onLogout:ho},null,8,["user"])])]),W("main",Di,[I(Z)]),I(Ai,{open:ke.value,query:Te.value,results:ae.value,loading:ze.value,hints:Rt,"onUpdate:query":_[8]||(_[8]=P=>Te.value=P),onClose:_[9]||(_[9]=P=>ke.value=!1),onSearchInput:Vt,onSelect:go,onApplyHint:vo},null,8,["open","query","results","loading"])])}}}),Vi=rn(Ri,[["__scopeId","data-v-b8201660"]]),Mi="modulepreload",Bi=function(e,t){return new URL(e,t).href},Rn={},E=function(t,n,o){let r=Promise.resolve();if(n&&n.length>0){let s=function(d){return Promise.all(d.map(c=>Promise.resolve(c).then(p=>({status:"fulfilled",value:p}),p=>({status:"rejected",reason:p}))))};const l=document.getElementsByTagName("link"),i=document.querySelector("meta[property=csp-nonce]"),u=i?.nonce||i?.getAttribute("nonce");r=s(n.map(d=>{if(d=Bi(d,o),d in Rn)return;Rn[d]=!0;const c=d.endsWith(".css"),p=c?'[rel="stylesheet"]':"";if(!!o)for(let y=l.length-1;y>=0;y--){const g=l[y];if(g.href===d&&(!c||g.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${d}"]${p}`))return;const f=document.createElement("link");if(f.rel=c?"stylesheet":Mi,c||(f.as="script"),f.crossOrigin="",f.href=d,u&&f.setAttribute("nonce",u),document.head.appendChild(f),c)return new Promise((y,g)=>{f.addEventListener("load",y),f.addEventListener("error",()=>g(new Error(`Unable to preload CSS for ${d}`)))})}))}function a(s){const l=new Event("vite:preloadError",{cancelable:!0});if(l.payload=s,window.dispatchEvent(l),!l.defaultPrevented)throw s}return r.then(s=>{for(const l of s||[])l.status==="rejected"&&a(l.reason);return t().catch(a)})};function Wi(e,t={}){const n=t.host??Pt,o=t.on===void 0?Do:t.on,r=No();t.initialPath&&r.replace(t.initialPath);const a=jo({history:r,routes:e});Ro(l=>a.resolve(l));let s;return a.afterEach(l=>{const i=s;s=void 0,n.onRouteChanged(l.fullPath,i)}),o&&o("@history",({path:l,navId:i})=>{if(!l)return;i!==void 0&&(s=i);const u=l.startsWith("/")?l:`/${l}`;a.currentRoute.value.fullPath!==u&&a.push(u)}),a}Le({name:"WippyHostRouterLink",props:{to:{type:String,required:!0}},setup(e,{slots:t}){return()=>Ge("a",{href:e.to,onClick:n=>{n.defaultPrevented||n.button!==0||n.metaKey||n.altKey||n.ctrlKey||n.shiftKey||(n.preventDefault(),Pt.navigate(e.to))}},t.default?.())}});Le({name:"WippyAutoRouterLink",props:{to:{type:[String,Object],required:!0},replace:{type:Boolean,default:!1},activeClass:{type:String,default:void 0},exactActiveClass:{type:String,default:void 0},ariaCurrentValue:{type:String,default:"page"},externalTarget:{type:String,default:"_blank"}},setup(e,{slots:t}){const n=Mn();return()=>{const o=n.resolve(e.to),r=Pt.classifyLink(o.href);if(r.kind==="host-nav")return Ge("a",{href:o.href,onClick:a=>{a.defaultPrevented||a.button===0&&(a.metaKey||a.altKey||a.ctrlKey||a.shiftKey||(a.preventDefault(),Pt.navigate(r.normalizedPath??r.href)))},"aria-current":e.ariaCurrentValue},t.default?.());if(r.kind==="external"){const a=e.externalTarget==="_blank";return Ge("a",{href:o.href,target:e.externalTarget||void 0,rel:a?"noopener noreferrer":void 0},t.default?.())}return r.kind==="ignore"?Ge("a",{href:o.href||"#",onClick:a=>a.preventDefault()},t.default?.()):Ge(Io,{to:e.to,replace:e.replace,activeClass:e.activeClass,exactActiveClass:e.exactActiveClass,ariaCurrentValue:e.ariaCurrentValue},t.default?{default:a=>t.default?.(a)}:void 0)}}});const Ui=[{path:"/",name:"dashboard",component:()=>E(()=>import("./assets/dashboard-BQftqJZE.js"),__vite__mapDeps([0,1,2,3,4,5,6,7,8]),import.meta.url)},{path:"/dataflows",name:"workflow",component:()=>E(()=>import("./assets/workflow-BnPrisCC.js"),__vite__mapDeps([9,3]),import.meta.url)},{path:"/sessions",name:"sessions",component:()=>E(()=>import("./assets/sessions-BrMpENKd.js"),__vite__mapDeps([10,11]),import.meta.url)},{path:"/session/:id",name:"session-detail",component:()=>E(()=>import("./assets/session-detail-BgaJxj_x.js"),__vite__mapDeps([12,1,13,14,15]),import.meta.url)},{path:"/agents",name:"agents",component:()=>E(()=>import("./assets/agents-ByacHkKz.js"),__vite__mapDeps([16,1,8,17,14,15,11]),import.meta.url)},{path:"/models",name:"models",component:()=>E(()=>import("./assets/models-BGLayZfU.js"),__vite__mapDeps([18,1,8,17,14,15,11]),import.meta.url)},{path:"/tools",name:"tools",component:()=>E(()=>import("./assets/tools-page-CAPkcnkU.js"),__vite__mapDeps([19,1,8,17,14,15,11]),import.meta.url)},{path:"/traits",name:"traits",component:()=>E(()=>import("./assets/traits-BCdYpwJm.js"),__vite__mapDeps([20,1,8,17,14,15,11]),import.meta.url)},{path:"/endpoints",name:"endpoints",component:()=>E(()=>import("./assets/endpoints-Va7stiZG.js"),__vite__mapDeps([21,1,17,14,15,11]),import.meta.url)},{path:"/policies",name:"policies",component:()=>E(()=>import("./assets/policies-C7MNLQNg.js"),__vite__mapDeps([22,1,8,17,14,15,11]),import.meta.url)},{path:"/structure",name:"structure",component:()=>E(()=>import("./assets/structure-BoeDRm0U.js"),__vite__mapDeps([23,8]),import.meta.url)},{path:"/dataflow/:id",name:"dataflow-detail",component:()=>E(()=>import("./assets/dataflow-detail-BZVhBmyi.js"),__vite__mapDeps([24,1,3,13,15]),import.meta.url)},{path:"/plugin/:id",name:"plugin",component:()=>E(()=>import("./assets/plugin-page-78CA4jh7.js"),__vite__mapDeps([25,26]),import.meta.url)},{path:"/logs",name:"logs",component:()=>E(()=>import("./assets/logger-CJ4vPYnn.js"),__vite__mapDeps([27,6,11]),import.meta.url)},{path:"/activity",name:"activity",component:()=>E(()=>import("./assets/activity-BTPuvvNP.js"),__vite__mapDeps([28,11]),import.meta.url)},{path:"/system",name:"system",component:()=>E(()=>import("./assets/system-Ba_7tip8.js"),__vite__mapDeps([29,2,11]),import.meta.url)},{path:"/tests",name:"tests",component:()=>E(()=>import("./assets/tests-C21pmcDl.js"),__vite__mapDeps([30,8]),import.meta.url)},{path:"/settings",name:"settings",component:()=>E(()=>import("./assets/settings-86u394KL.js"),__vite__mapDeps([31,11]),import.meta.url)},{path:"/settings/environment",name:"settings-environment",component:()=>E(()=>import("./assets/settings-environment-DV741d7r.js"),__vite__mapDeps([32,11]),import.meta.url)},{path:"/settings/registry",name:"settings-registry",component:()=>E(()=>import("./assets/settings-registry-CUu_UwsG.js"),__vite__mapDeps([33,11]),import.meta.url)},{path:"/settings/hub",name:"settings-hub",component:()=>E(()=>import("./assets/settings-hub-VxWUSLw0.js"),__vite__mapDeps([34,1,35,11]),import.meta.url)},{path:"/settings/hub/:org/:name",name:"settings-hub-module",component:()=>E(()=>import("./assets/settings-hub-module-R7tsGer5.js"),__vite__mapDeps([36,1,35]),import.meta.url)},{path:"/knowledge",name:"knowledge",component:()=>E(()=>import("./assets/knowledge-B7f2toOe.js"),__vite__mapDeps([37,7,13]),import.meta.url)},{path:"/mcp",name:"mcp",component:()=>E(()=>import("./assets/mcp-TswBPJzT.js"),[],import.meta.url)},{path:"/components",name:"components",component:()=>E(()=>import("./assets/components-C4F7M12i.js"),__vite__mapDeps([38,13,15]),import.meta.url)},{path:"/tasks",name:"tasks",component:()=>E(()=>import("./assets/tasks-C61-GdIs.js"),__vite__mapDeps([39,4]),import.meta.url)},{path:"/tasks/:id",name:"task-detail",component:()=>E(()=>import("./assets/task-detail-CkwwjE7P.js"),__vite__mapDeps([40,1,4,13]),import.meta.url)},{path:"/changes",name:"changes",component:()=>E(()=>import("./assets/changes-DTloMyYz.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/changes/:id",name:"changes-detail",component:()=>E(()=>import("./assets/changes-DTloMyYz.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/audit",name:"audit",component:()=>E(()=>import("./assets/audit-CZqtKQmG.js"),[],import.meta.url)},{path:"/:pathMatch(.*)*",name:"not-found",redirect:"/"}];function zi(e,t,n){return Wi(Ui,{initialPath:n,host:e,on:t})}async function Hi(){const e=await window.$W.config(),t=await window.$W.host(),n=await window.$W.api(),o=await window.$W.instance();n.interceptors.response.use(u=>u,u=>(u?.response?.status===401&&t.handleError("auth-expired",{url:u?.config?.url,method:u?.config?.method,message:u?.message}),Promise.reject(u)));let r=null;try{r=await window.$W.on()}catch{}const a=e.context?.route||"/",s=e.theming?.global?.icons??e.theming?.global?.iconSets?.custom;s&&yo({prefix:"custom",icons:s});const l=Eo(Vi);l.use(So()),l.use(zr),l.provide(lo,t),l.provide(uo,n),l.provide(co,o),l.provide(po,e),r&&l.provide(qa,r);const i=zi(t,o.on,a);return l.use(i),l}async function qi(e="#app"){const t=await Hi();return t.mount(e),t}qi();export{ss as $,Ps as A,xs as B,ws as C,ta as D,ps as E,R as F,rs as G,as as H,w as I,ls as J,D as K,is as L,ar as M,es as N,cs as O,Xi as P,nn as Q,Na as R,Ze as S,Jo as T,er as U,rr as V,qn as W,ns as X,ir as Y,Kt as Z,rn as _,so as a,zn as a0,io as a1,Fn as a2,us as a3,fn as a4,mn as a5,Ji as a6,Zi as a7,ds as a8,os as a9,ts as aa,Ne as ab,pn as ac,ms as b,Os as c,Ga as d,Es as e,As as f,Ss as g,Cs as h,Ts as i,Ka as j,bs as k,fs as l,E as m,kt as n,bo as o,_s as p,vs as q,gs as r,We as s,Dn as t,Fa as u,ei as v,hs as w,ys as x,$s as y,ks as z};
