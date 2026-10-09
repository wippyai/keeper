const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./assets/dashboard-C2-SJOXN.js","./assets/index-kJ3bsOU1.js","./assets/pm-Dj_62FpQ.js","./assets/dataflows-Dr2Ef8bh.js","./assets/tasks-CxgCqZXy.js","./assets/changelog-kS_NZw1C.js","./assets/logger-Cq9hvQPy.js","./assets/knowledge-iW30SVUZ.js","./assets/utils-CSjTgnrH.js","./assets/workflow-BnPrisCC.js","./assets/sessions-BrMpENKd.js","./assets/PageHeader.vue_vue_type_script_setup_true_lang-x-0LZxLa.js","./assets/session-detail-BgaJxj_x.js","./assets/MarkdownContent-DyBNkW15.js","./assets/DetailPanel.vue_vue_type_script_setup_true_lang-B115sO7W.js","./assets/JsonBlock.vue_vue_type_script_setup_true_lang-D4lkhHol.js","./assets/agents-ByacHkKz.js","./assets/EntryDetailPanel-Bg-7l0js.js","./assets/models-BGLayZfU.js","./assets/tools-page-CAPkcnkU.js","./assets/traits-BCdYpwJm.js","./assets/endpoints-Va7stiZG.js","./assets/policies-C7MNLQNg.js","./assets/structure-BoeDRm0U.js","./assets/dataflow-detail-BZVhBmyi.js","./assets/plugin-page-78CA4jh7.js","./assets/PluginHost-DUK2xtKt.js","./assets/logger-CJ4vPYnn.js","./assets/activity-BTPuvvNP.js","./assets/system-Ba_7tip8.js","./assets/tests-C21pmcDl.js","./assets/settings-86u394KL.js","./assets/settings-environment-DV741d7r.js","./assets/settings-registry-CUu_UwsG.js","./assets/settings-hub-7zVX1Nd8.js","./assets/HubInstallDialog-D8Gid44a.js","./assets/settings-hub-module-B1YBrV81.js","./assets/knowledge-B7f2toOe.js","./assets/components-C4F7M12i.js","./assets/tasks-C61-GdIs.js","./assets/task-detail-CkwwjE7P.js","./assets/changes-DTloMyYz.js"])))=>i.map(i=>d[i]);
import{Icon as K,addCollection as go}from"@iconify/vue";import{createPinia as ho}from"pinia";import{ref as V,readonly as yo,getCurrentInstance as ln,onMounted as Vn,nextTick as So,watch as Re,reactive as _o,useId as wo,mergeProps as J,openBlock as O,createElementBlock as E,createElementVNode as M,renderSlot as Fe,createTextVNode as Xe,toDisplayString as X,resolveComponent as Ut,resolveDirective as $o,withDirectives as ko,createBlock as Me,resolveDynamicComponent as Po,withCtx as Be,createCommentVNode as F,normalizeClass as Te,inject as en,defineComponent as Ee,createVNode as j,unref as C,Fragment as et,renderList as tt,Teleport as xo,withModifiers as Oo,withKeys as un,normalizeStyle as zt,computed as q,onUnmounted as To,h as Ge,createApp as Co}from"vue";import{useRouter as Mn,useRoute as Ao,createMemoryHistory as Eo,createRouter as Lo,RouterLink as No}from"vue-router";import{host as Pt,on as jo,setLocalRouter as Io}from"@wippy-fe/proxy";(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))o(r);new MutationObserver(r=>{for(const a of r)if(a.type==="childList")for(const s of a.addedNodes)s.tagName==="LINK"&&s.rel==="modulepreload"&&o(s)}).observe(document,{childList:!0,subtree:!0});function n(r){const a={};return r.integrity&&(a.integrity=r.integrity),r.referrerPolicy&&(a.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?a.credentials="include":r.crossOrigin==="anonymous"?a.credentials="omit":a.credentials="same-origin",a}function o(r){if(r.ep)return;r.ep=!0;const a=n(r);fetch(r.href,a)}})();var Do=Object.defineProperty,dn=Object.getOwnPropertySymbols,Ro=Object.prototype.hasOwnProperty,Vo=Object.prototype.propertyIsEnumerable,cn=(e,t,n)=>t in e?Do(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,Mo=(e,t)=>{for(var n in t||(t={}))Ro.call(t,n)&&cn(e,n,t[n]);if(dn)for(var n of dn(t))Vo.call(t,n)&&cn(e,n,t[n]);return e};function Le(e){return e==null||e===""||Array.isArray(e)&&e.length===0||!(e instanceof Date)&&typeof e=="object"&&Object.keys(e).length===0}function Ht(e,t,n=new WeakSet){if(e===t)return!0;if(!e||!t||typeof e!="object"||typeof t!="object"||n.has(e)||n.has(t))return!1;n.add(e).add(t);let o=Array.isArray(e),r=Array.isArray(t),a,s,l;if(o&&r){if(s=e.length,s!=t.length)return!1;for(a=s;a--!==0;)if(!Ht(e[a],t[a],n))return!1;return!0}if(o!=r)return!1;let i=e instanceof Date,u=t instanceof Date;if(i!=u)return!1;if(i&&u)return e.getTime()==t.getTime();let d=e instanceof RegExp,c=t instanceof RegExp;if(d!=c)return!1;if(d&&c)return e.toString()==t.toString();let p=Object.keys(e);if(s=p.length,s!==Object.keys(t).length)return!1;for(a=s;a--!==0;)if(!Object.prototype.hasOwnProperty.call(t,p[a]))return!1;for(a=s;a--!==0;)if(l=p[a],!Ht(e[l],t[l],n))return!1;return!0}function Bo(e,t){return Ht(e,t)}function Tt(e){return typeof e=="function"&&"call"in e&&"apply"in e}function I(e){return!Le(e)}function pn(e,t){if(!e||!t)return null;try{let n=e[t];if(I(n))return n}catch{}if(Object.keys(e).length){if(Tt(t))return t(e);if(t.indexOf(".")===-1)return e[t];{let n=t.split("."),o=e;for(let r=0,a=n.length;r<a;++r){if(o==null)return null;o=o[n[r]]}return o}}return null}function Yi(e,t,n){return n?pn(e,n)===pn(t,n):Bo(e,t)}function ge(e,t=!0){return e instanceof Object&&e.constructor===Object&&(t||Object.keys(e).length!==0)}function Bn(e={},t={}){let n=Mo({},e);return Object.keys(t).forEach(o=>{let r=o;ge(t[r])&&r in e&&ge(e[r])?n[r]=Bn(e[r],t[r]):n[r]=t[r]}),n}function Wo(...e){return e.reduce((t,n,o)=>o===0?n:Bn(t,n),{})}function Qi(e,t){let n=-1;if(I(e))try{n=e.findLastIndex(t)}catch{n=e.lastIndexOf([...e].reverse().find(t))}return n}function se(e,...t){return Tt(e)?e(...t):e}function ee(e,t=!0){return typeof e=="string"&&(t||e!=="")}function ve(e){return ee(e)?e.replace(/(-|_)/g,"").toLowerCase():e}function tn(e,t="",n={}){let o=ve(t).split("."),r=o.shift();if(r){if(ge(e)){let a=Object.keys(e).find(s=>ve(s)===r)||"";return tn(se(e[a],n),o.join("."),n)}return}return se(e,n)}function Wn(e,t=!0){return Array.isArray(e)&&(t||e.length!==0)}function Uo(e){return I(e)&&!isNaN(e)}function Ce(e,t){if(t){let n=t.test(e);return t.lastIndex=0,n}return!1}function zo(...e){return Wo(...e)}function Qe(e){return e&&e.replace(/\/\*(?:(?!\*\/)[\s\S])*\*\/|[\r\n\t]+/g,"").replace(/ {2,}/g," ").replace(/ ([{:}]) /g,"$1").replace(/([;,]) /g,"$1").replace(/ !/g,"!").replace(/: /g,":").trim()}function Ho(e){return ee(e,!1)?e[0].toUpperCase()+e.slice(1):e}function Un(e){return ee(e)?e.replace(/(_)/g,"-").replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase():e}function zn(){let e=new Map;return{on(t,n){let o=e.get(t);return o?o.push(n):o=[n],e.set(t,o),this},off(t,n){let o=e.get(t);return o&&o.splice(o.indexOf(n)>>>0,1),this},emit(t,n){let o=e.get(t);o&&o.forEach(r=>{r(n)})},clear(){e.clear()}}}function Ze(...e){if(e){let t=[];for(let n=0;n<e.length;n++){let o=e[n];if(!o)continue;let r=typeof o;if(r==="string"||r==="number")t.push(o);else if(r==="object"){let a=Array.isArray(o)?[Ze(...o)]:Object.entries(o).map(([s,l])=>l?s:void 0);t=a.length?t.concat(a.filter(s=>!!s)):t}}return t.join(" ").trim()}}function qo(e,t){return e?e.classList?e.classList.contains(t):new RegExp("(^| )"+t+"( |$)","gi").test(e.className):!1}function qt(e,t){if(e&&t){let n=o=>{qo(e,o)||(e.classList?e.classList.add(o):e.className+=" "+o)};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Ko(){return window.innerWidth-document.documentElement.offsetWidth}function Zi(e){typeof e=="string"?qt(document.body,e||"p-overflow-hidden"):(e!=null&&e.variableName&&document.body.style.setProperty(e.variableName,Ko()+"px"),qt(document.body,e?.className||"p-overflow-hidden"))}function Je(e,t){if(e&&t){let n=o=>{e.classList?e.classList.remove(o):e.className=e.className.replace(new RegExp("(^|\\b)"+o.split(" ").join("|")+"(\\b|$)","gi")," ")};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Ji(e){typeof e=="string"?Je(document.body,e||"p-overflow-hidden"):(e!=null&&e.variableName&&document.body.style.removeProperty(e.variableName),Je(document.body,e?.className||"p-overflow-hidden"))}function Kt(e){for(let t of document?.styleSheets)try{for(let n of t?.cssRules)for(let o of n?.style)if(e.test(o))return{name:o,value:n.style.getPropertyValue(o).trim()}}catch{}return null}function Hn(e){let t={width:0,height:0};if(e){let[n,o]=[e.style.visibility,e.style.display],r=e.getBoundingClientRect();e.style.visibility="hidden",e.style.display="block",t.width=r.width||e.offsetWidth,t.height=r.height||e.offsetHeight,e.style.display=o,e.style.visibility=n}return t}function qn(){let e=window,t=document,n=t.documentElement,o=t.getElementsByTagName("body")[0],r=e.innerWidth||n.clientWidth||o.clientWidth,a=e.innerHeight||n.clientHeight||o.clientHeight;return{width:r,height:a}}function Ft(e){return e?Math.abs(e.scrollLeft):0}function Fo(){let e=document.documentElement;return(window.pageXOffset||Ft(e))-(e.clientLeft||0)}function Go(){let e=document.documentElement;return(window.pageYOffset||e.scrollTop)-(e.clientTop||0)}function Yo(e){return e?getComputedStyle(e).direction==="rtl":!1}function Xi(e,t,n=!0){var o,r,a,s;if(e){let l=e.offsetParent?{width:e.offsetWidth,height:e.offsetHeight}:Hn(e),i=l.height,u=l.width,d=t.offsetHeight,c=t.offsetWidth,p=t.getBoundingClientRect(),m=Go(),f=Fo(),y=qn(),g,_,k="top";p.top+d+i>y.height?(g=p.top+m-i,k="bottom",g<0&&(g=m)):g=d+p.top+m,p.left+u>y.width?_=Math.max(0,p.left+f+c-u):_=p.left+f,Yo(e)?e.style.insetInlineEnd=_+"px":e.style.insetInlineStart=_+"px",e.style.top=g+"px",e.style.transformOrigin=k,n&&(e.style.marginTop=k==="bottom"?`calc(${(r=(o=Kt(/-anchor-gutter$/))==null?void 0:o.value)!=null?r:"2px"} * -1)`:(s=(a=Kt(/-anchor-gutter$/))==null?void 0:a.value)!=null?s:"")}}function es(e,t){e&&(typeof t=="string"?e.style.cssText=t:Object.entries(t||{}).forEach(([n,o])=>e.style[n]=o))}function Qo(e,t){return e instanceof HTMLElement?e.offsetWidth:0}function ts(e,t,n=!0,o=void 0){var r;if(e){let a=e.offsetParent?{width:e.offsetWidth,height:e.offsetHeight}:Hn(e),s=t.offsetHeight,l=t.getBoundingClientRect(),i=qn(),u,d,c=o??"top";if(!o&&l.top+s+a.height>i.height?(u=-1*a.height,c="bottom",l.top+u<0&&(u=-1*l.top)):u=s,a.width>i.width?d=l.left*-1:l.left+a.width>i.width?d=(l.left+a.width-i.width)*-1:d=0,e.style.top=u+"px",e.style.insetInlineStart=d+"px",e.style.transformOrigin=c,n){let p=(r=Kt(/-anchor-gutter$/))==null?void 0:r.value;e.style.marginTop=c==="bottom"?`calc(${p??"2px"} * -1)`:p??""}}}function Kn(e){if(e){let t=e.parentNode;return t&&t instanceof ShadowRoot&&t.host&&(t=t.host),t}return null}function Zo(e){return!!(e!==null&&typeof e<"u"&&e.nodeName&&Kn(e))}function Ne(e){return typeof Element<"u"?e instanceof Element:e!==null&&typeof e=="object"&&e.nodeType===1&&typeof e.nodeName=="string"}function xt(e,t={}){if(Ne(e)){let n=(o,r)=>{var a,s;let l=(a=e?.$attrs)!=null&&a[o]?[(s=e?.$attrs)==null?void 0:s[o]]:[];return[r].flat().reduce((i,u)=>{if(u!=null){let d=typeof u;if(d==="string"||d==="number")i.push(u);else if(d==="object"){let c=Array.isArray(u)?n(o,u):Object.entries(u).map(([p,m])=>o==="style"&&(m||m===0)?`${p.replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()}:${m}`:m?p:void 0);i=c.length?i.concat(c.filter(p=>!!p)):i}}return i},l)};Object.entries(t).forEach(([o,r])=>{if(r!=null){let a=o.match(/^on(.+)/);a?e.addEventListener(a[1].toLowerCase(),r):o==="p-bind"||o==="pBind"?xt(e,r):(r=o==="class"?[...new Set(n("class",r))].join(" ").trim():o==="style"?n("style",r).join(";").trim():r,(e.$attrs=e.$attrs||{})&&(e.$attrs[o]=r),e.setAttribute(o,r))}})}}function Jo(e,t={},...n){{let o=document.createElement(e);return xt(o,t),o.append(...n),o}}function Xo(e,t){return Ne(e)?Array.from(e.querySelectorAll(t)):[]}function Fn(e,t){return Ne(e)?e.matches(t)?e:e.querySelector(t):null}function ns(e,t){e&&document.activeElement!==e&&e.focus(t)}function er(e,t){if(Ne(e)){let n=e.getAttribute(t);return isNaN(n)?n==="true"||n==="false"?n==="true":n:+n}}function Gn(e,t=""){let n=Xo(e,`button:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [href]:not([tabindex = "-1"]):not([style*="display:none"]):not([hidden])${t},
            input:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            select:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            textarea:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [tabIndex]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [contenteditable]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t}`),o=[];for(let r of n)getComputedStyle(r).display!="none"&&getComputedStyle(r).visibility!="hidden"&&o.push(r);return o}function os(e,t){let n=Gn(e,t);return n.length>0?n[0]:null}function mn(e){if(e){let t=e.offsetHeight,n=getComputedStyle(e);return t-=parseFloat(n.paddingTop)+parseFloat(n.paddingBottom)+parseFloat(n.borderTopWidth)+parseFloat(n.borderBottomWidth),t}return 0}function rs(e,t){let n=Gn(e,t);return n.length>0?n[n.length-1]:null}function tr(e){if(e){let t=e.getBoundingClientRect();return{top:t.top+(window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0),left:t.left+(window.pageXOffset||Ft(document.documentElement)||Ft(document.body)||0)}}return{top:"auto",left:"auto"}}function nr(e,t){return e?e.offsetHeight:0}function Yn(e,t=[]){let n=Kn(e);return n===null?t:Yn(n,t.concat([n]))}function as(e){let t=[];if(e){let n=Yn(e),o=/(auto|scroll)/,r=a=>{try{let s=window.getComputedStyle(a,null);return o.test(s.getPropertyValue("overflow"))||o.test(s.getPropertyValue("overflowX"))||o.test(s.getPropertyValue("overflowY"))}catch{return!1}};for(let a of n){let s=a.nodeType===1&&a.dataset.scrollselectors;if(s){let l=s.split(",");for(let i of l){let u=Fn(a,i);u&&r(u)&&t.push(u)}}a.nodeType!==9&&r(a)&&t.push(a)}}return t}function fn(e){if(e){let t=e.offsetWidth,n=getComputedStyle(e);return t-=parseFloat(n.paddingLeft)+parseFloat(n.paddingRight)+parseFloat(n.borderLeftWidth)+parseFloat(n.borderRightWidth),t}return 0}function or(){return!!(typeof window<"u"&&window.document&&window.document.createElement)}function is(e,t=""){return Ne(e)?e.matches(`button:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [href][clientHeight][clientWidth]:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            input:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            select:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            textarea:not([tabindex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [tabIndex]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t},
            [contenteditable]:not([tabIndex = "-1"]):not([disabled]):not([style*="display:none"]):not([hidden])${t}`):!1}function ss(e){return!!(e&&e.offsetParent!=null)}function ls(){return"ontouchstart"in window||navigator.maxTouchPoints>0||navigator.msMaxTouchPoints>0}function rr(e,t="",n){Ne(e)&&n!==null&&n!==void 0&&e.setAttribute(t,n)}var yt={};function ar(e="pui_id_"){return Object.hasOwn(yt,e)||(yt[e]=0),yt[e]++,`${e}${yt[e]}`}var ir=Object.defineProperty,sr=Object.defineProperties,lr=Object.getOwnPropertyDescriptors,Ot=Object.getOwnPropertySymbols,Qn=Object.prototype.hasOwnProperty,Zn=Object.prototype.propertyIsEnumerable,bn=(e,t,n)=>t in e?ir(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,fe=(e,t)=>{for(var n in t||(t={}))Qn.call(t,n)&&bn(e,n,t[n]);if(Ot)for(var n of Ot(t))Zn.call(t,n)&&bn(e,n,t[n]);return e},Vt=(e,t)=>sr(e,lr(t)),ye=(e,t)=>{var n={};for(var o in e)Qn.call(e,o)&&t.indexOf(o)<0&&(n[o]=e[o]);if(e!=null&&Ot)for(var o of Ot(e))t.indexOf(o)<0&&Zn.call(e,o)&&(n[o]=e[o]);return n},ur=zn(),U=ur,nt=/{([^}]*)}/g,Jn=/(\d+\s+[\+\-\*\/]\s+\d+)/g,Xn=/var\([^)]+\)/g;function vn(e){return ee(e)?e.replace(/[A-Z]/g,(t,n)=>n===0?t:"."+t.toLowerCase()).toLowerCase():e}function dr(e){return ge(e)&&e.hasOwnProperty("$value")&&e.hasOwnProperty("$type")?e.$value:e}function cr(e){return e.replaceAll(/ /g,"").replace(/[^\w]/g,"-")}function Gt(e="",t=""){return cr(`${ee(e,!1)&&ee(t,!1)?`${e}-`:e}${t}`)}function eo(e="",t=""){return`--${Gt(e,t)}`}function pr(e=""){let t=(e.match(/{/g)||[]).length,n=(e.match(/}/g)||[]).length;return(t+n)%2!==0}function to(e,t="",n="",o=[],r){if(ee(e)){let a=e.trim();if(pr(a))return;if(Ce(a,nt)){let s=a.replaceAll(nt,l=>{let i=l.replace(/{|}/g,"").split(".").filter(u=>!o.some(d=>Ce(u,d)));return`var(${eo(n,Un(i.join("-")))}${I(r)?`, ${r}`:""})`});return Ce(s.replace(Xn,"0"),Jn)?`calc(${s})`:s}return a}else if(Uo(e))return e}function mr(e,t,n){ee(t,!1)&&e.push(`${t}:${n};`)}function De(e,t){return e?`${e}{${t}}`:""}function no(e,t){if(e.indexOf("dt(")===-1)return e;function n(s,l){let i=[],u=0,d="",c=null,p=0;for(;u<=s.length;){let m=s[u];if((m==='"'||m==="'"||m==="`")&&s[u-1]!=="\\"&&(c=c===m?null:m),!c&&(m==="("&&p++,m===")"&&p--,(m===","||u===s.length)&&p===0)){let f=d.trim();f.startsWith("dt(")?i.push(no(f,l)):i.push(o(f)),d="",u++;continue}m!==void 0&&(d+=m),u++}return i}function o(s){let l=s[0];if((l==='"'||l==="'"||l==="`")&&s[s.length-1]===l)return s.slice(1,-1);let i=Number(s);return isNaN(i)?s:i}let r=[],a=[];for(let s=0;s<e.length;s++)if(e[s]==="d"&&e.slice(s,s+3)==="dt(")a.push(s),s+=2;else if(e[s]===")"&&a.length>0){let l=a.pop();a.length===0&&r.push([l,s])}if(!r.length)return e;for(let s=r.length-1;s>=0;s--){let[l,i]=r[s],u=e.slice(l+3,i),d=n(u,t),c=t(...d);e=e.slice(0,l)+c+e.slice(i+1)}return e}var us=e=>{var t;let n=L.getTheme(),o=Yt(n,e,void 0,"variable"),r=(t=o?.match(/--[\w-]+/g))==null?void 0:t[0],a=Yt(n,e,void 0,"value");return{name:r,variable:o,value:a}},Ae=(...e)=>Yt(L.getTheme(),...e),Yt=(e={},t,n,o)=>{if(t){let{variable:r,options:a}=L.defaults||{},{prefix:s,transform:l}=e?.options||a||{},i=Ce(t,nt)?t:`{${t}}`;return o==="value"||Le(o)&&l==="strict"?L.getTokenValue(t):to(i,void 0,s,[r.excludedKeyRegex],n)}return""};function St(e,...t){if(e instanceof Array){let n=e.reduce((o,r,a)=>{var s;return o+r+((s=se(t[a],{dt:Ae}))!=null?s:"")},"");return no(n,Ae)}return se(e,{dt:Ae})}function fr(e,t={}){let n=L.defaults.variable,{prefix:o=n.prefix,selector:r=n.selector,excludedKeyRegex:a=n.excludedKeyRegex}=t,s=[],l=[],i=[{node:e,path:o}];for(;i.length;){let{node:d,path:c}=i.pop();for(let p in d){let m=d[p],f=dr(m),y=Ce(p,a)?Gt(c):Gt(c,Un(p));if(ge(f))i.push({node:f,path:y});else{let g=eo(y),_=to(f,y,o,[a]);mr(l,g,_);let k=y;o&&k.startsWith(o+"-")&&(k=k.slice(o.length+1)),s.push(k.replace(/-/g,"."))}}}let u=l.join("");return{value:l,tokens:s,declarations:u,css:De(r,u)}}var me={regex:{rules:{class:{pattern:/^\.([a-zA-Z][\w-]*)$/,resolve(e){return{type:"class",selector:e,matched:this.pattern.test(e.trim())}}},attr:{pattern:/^\[(.*)\]$/,resolve(e){return{type:"attr",selector:`:root${e},:host${e}`,matched:this.pattern.test(e.trim())}}},media:{pattern:/^@media (.*)$/,resolve(e){return{type:"media",selector:e,matched:this.pattern.test(e.trim())}}},system:{pattern:/^system$/,resolve(e){return{type:"system",selector:"@media (prefers-color-scheme: dark)",matched:this.pattern.test(e.trim())}}},custom:{resolve(e){return{type:"custom",selector:e,matched:!0}}}},resolve(e){let t=Object.keys(this.rules).filter(n=>n!=="custom").map(n=>this.rules[n]);return[e].flat().map(n=>{var o;return(o=t.map(r=>r.resolve(n)).find(r=>r.matched))!=null?o:this.rules.custom.resolve(n)})}},_toVariables(e,t){return fr(e,{prefix:t?.prefix})},getCommon({name:e="",theme:t={},params:n,set:o,defaults:r}){var a,s,l,i,u,d,c;let{preset:p,options:m}=t,f,y,g,_,k,N,v;if(I(p)&&m.transform!=="strict"){let{primitive:w,semantic:B,extend:H}=p,ue=B||{},{colorScheme:de}=ue,ce=ye(ue,["colorScheme"]),G=H||{},{colorScheme:te}=G,ne=ye(G,["colorScheme"]),Y=de||{},{dark:oe}=Y,re=ye(Y,["dark"]),he=te||{},{dark:Se}=he,_e=ye(he,["dark"]),pe=I(w)?this._toVariables({primitive:w},m):{},le=I(ce)?this._toVariables({semantic:ce},m):{},R=I(re)?this._toVariables({light:re},m):{},je=I(oe)?this._toVariables({dark:oe},m):{},we=I(ne)?this._toVariables({semantic:ne},m):{},ft=I(_e)?this._toVariables({light:_e},m):{},bt=I(Se)?this._toVariables({dark:Se},m):{},[At,vt]=[(a=pe.declarations)!=null?a:"",pe.tokens],[Ie,Et]=[(s=le.declarations)!=null?s:"",le.tokens||[]],[xe,Lt]=[(l=R.declarations)!=null?l:"",R.tokens||[]],[gt,Nt]=[(i=je.declarations)!=null?i:"",je.tokens||[]],[jt,$e]=[(u=we.declarations)!=null?u:"",we.tokens||[]],[Oe,ae]=[(d=ft.declarations)!=null?d:"",ft.tokens||[]],[ze,He]=[(c=bt.declarations)!=null?c:"",bt.tokens||[]];f=this.transformCSS(e,At,"light","variable",m,o,r),y=vt;let It=this.transformCSS(e,`${Ie}${xe}`,"light","variable",m,o,r),ht=this.transformCSS(e,`${gt}`,"dark","variable",m,o,r);g=`${It}${ht}`,_=[...new Set([...Et,...Lt,...Nt])];let Dt=this.transformCSS(e,`${jt}${Oe}color-scheme:light`,"light","variable",m,o,r),Rt=this.transformCSS(e,`${ze}color-scheme:dark`,"dark","variable",m,o,r);k=`${Dt}${Rt}`,N=[...new Set([...$e,...ae,...He])],v=se(p.css,{dt:Ae})}return{primitive:{css:f,tokens:y},semantic:{css:g,tokens:_},global:{css:k,tokens:N},style:v}},getPreset({name:e="",preset:t={},options:n,params:o,set:r,defaults:a,selector:s}){var l,i,u;let d,c,p;if(I(t)&&n.transform!=="strict"){let m=e.replace("-directive",""),f=t,{colorScheme:y,extend:g,css:_}=f,k=ye(f,["colorScheme","extend","css"]),N=g||{},{colorScheme:v}=N,w=ye(N,["colorScheme"]),B=y||{},{dark:H}=B,ue=ye(B,["dark"]),de=v||{},{dark:ce}=de,G=ye(de,["dark"]),te=I(k)?this._toVariables({[m]:fe(fe({},k),w)},n):{},ne=I(ue)?this._toVariables({[m]:fe(fe({},ue),G)},n):{},Y=I(H)?this._toVariables({[m]:fe(fe({},H),ce)},n):{},[oe,re]=[(l=te.declarations)!=null?l:"",te.tokens||[]],[he,Se]=[(i=ne.declarations)!=null?i:"",ne.tokens||[]],[_e,pe]=[(u=Y.declarations)!=null?u:"",Y.tokens||[]],le=this.transformCSS(m,`${oe}${he}`,"light","variable",n,r,a,s),R=this.transformCSS(m,_e,"dark","variable",n,r,a,s);d=`${le}${R}`,c=[...new Set([...re,...Se,...pe])],p=se(_,{dt:Ae})}return{css:d,tokens:c,style:p}},getPresetC({name:e="",theme:t={},params:n,set:o,defaults:r}){var a;let{preset:s,options:l}=t,i=(a=s?.components)==null?void 0:a[e];return this.getPreset({name:e,preset:i,options:l,params:n,set:o,defaults:r})},getPresetD({name:e="",theme:t={},params:n,set:o,defaults:r}){var a,s;let l=e.replace("-directive",""),{preset:i,options:u}=t,d=((a=i?.components)==null?void 0:a[l])||((s=i?.directives)==null?void 0:s[l]);return this.getPreset({name:l,preset:d,options:u,params:n,set:o,defaults:r})},applyDarkColorScheme(e){return!(e.darkModeSelector==="none"||e.darkModeSelector===!1)},getColorSchemeOption(e,t){var n;return this.applyDarkColorScheme(e)?this.regex.resolve(e.darkModeSelector===!0?t.options.darkModeSelector:(n=e.darkModeSelector)!=null?n:t.options.darkModeSelector):[]},getLayerOrder(e,t={},n,o){let{cssLayer:r}=t;return r?`@layer ${se(r.order||r.name||"primeui",n)}`:""},getCommonStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:a}){let s=this.getCommon({name:e,theme:t,params:n,set:r,defaults:a}),l=Object.entries(o).reduce((i,[u,d])=>i.push(`${u}="${d}"`)&&i,[]).join(" ");return Object.entries(s||{}).reduce((i,[u,d])=>{if(ge(d)&&Object.hasOwn(d,"css")){let c=Qe(d.css),p=`${u}-variables`;i.push(`<style type="text/css" data-primevue-style-id="${p}" ${l}>${c}</style>`)}return i},[]).join("")},getStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:a}){var s;let l={name:e,theme:t,params:n,set:r,defaults:a},i=(s=e.includes("-directive")?this.getPresetD(l):this.getPresetC(l))==null?void 0:s.css,u=Object.entries(o).reduce((d,[c,p])=>d.push(`${c}="${p}"`)&&d,[]).join(" ");return i?`<style type="text/css" data-primevue-style-id="${e}-variables" ${u}>${Qe(i)}</style>`:""},createTokens(e={},t,n="",o="",r={}){let a=function(l,i={},u=[]){if(u.includes(this.path))return console.warn(`Circular reference detected at ${this.path}`),{colorScheme:l,path:this.path,paths:i,value:void 0};u.push(this.path),i.name=this.path,i.binding||(i.binding={});let d=this.value;if(typeof this.value=="string"&&nt.test(this.value)){let c=this.value.trim().replace(nt,p=>{var m;let f=p.slice(1,-1),y=this.tokens[f];if(!y)return console.warn(`Token not found for path: ${f}`),"__UNRESOLVED__";let g=y.computed(l,i,u);return Array.isArray(g)&&g.length===2?`light-dark(${g[0].value},${g[1].value})`:(m=g?.value)!=null?m:"__UNRESOLVED__"});d=Jn.test(c.replace(Xn,"0"))?`calc(${c})`:c}return Le(i.binding)&&delete i.binding,u.pop(),{colorScheme:l,path:this.path,paths:i,value:d.includes("__UNRESOLVED__")?void 0:d}},s=(l,i,u)=>{Object.entries(l).forEach(([d,c])=>{let p=Ce(d,t.variable.excludedKeyRegex)?i:i?`${i}.${vn(d)}`:vn(d),m=u?`${u}.${d}`:d;ge(c)?s(c,p,m):(r[p]||(r[p]={paths:[],computed:(f,y={},g=[])=>{if(r[p].paths.length===1)return r[p].paths[0].computed(r[p].paths[0].scheme,y.binding,g);if(f&&f!=="none")for(let _=0;_<r[p].paths.length;_++){let k=r[p].paths[_];if(k.scheme===f)return k.computed(f,y.binding,g)}return r[p].paths.map(_=>_.computed(_.scheme,y[_.scheme],g))}}),r[p].paths.push({path:m,value:c,scheme:m.includes("colorScheme.light")?"light":m.includes("colorScheme.dark")?"dark":"none",computed:a,tokens:r}))})};return s(e,n,o),r},getTokenValue(e,t,n){var o;let r=(l=>l.split(".").filter(i=>!Ce(i.toLowerCase(),n.variable.excludedKeyRegex)).join("."))(t),a=t.includes("colorScheme.light")?"light":t.includes("colorScheme.dark")?"dark":void 0,s=[(o=e[r])==null?void 0:o.computed(a)].flat().filter(l=>l);return s.length===1?s[0].value:s.reduce((l={},i)=>{let u=i,{colorScheme:d}=u,c=ye(u,["colorScheme"]);return l[d]=c,l},void 0)},getSelectorRule(e,t,n,o){return n==="class"||n==="attr"?De(I(t)?`${e}${t},${e} ${t}`:e,o):De(e,De(t??":root,:host",o))},transformCSS(e,t,n,o,r={},a,s,l){if(I(t)){let{cssLayer:i}=r;if(o!=="style"){let u=this.getColorSchemeOption(r,s);t=n==="dark"?u.reduce((d,{type:c,selector:p})=>(I(p)&&(d+=p.includes("[CSS]")?p.replace("[CSS]",t):this.getSelectorRule(p,l,c,t)),d),""):De(l??":root,:host",t)}if(i){let u={name:"primeui"};ge(i)&&(u.name=se(i.name,{name:e,type:o})),I(u.name)&&(t=De(`@layer ${u.name}`,t),a?.layerNames(u.name))}return t}return""}},L={defaults:{variable:{prefix:"p",selector:":root,:host",excludedKeyRegex:/^(primitive|semantic|components|directives|variables|colorscheme|light|dark|common|root|states|extend|css)$/gi},options:{prefix:"p",darkModeSelector:"system",cssLayer:!1}},_theme:void 0,_layerNames:new Set,_loadedStyleNames:new Set,_loadingStyles:new Set,_tokens:{},update(e={}){let{theme:t}=e;t&&(this._theme=Vt(fe({},t),{options:fe(fe({},this.defaults.options),t.options)}),this._tokens=me.createTokens(this.preset,this.defaults),this.clearLoadedStyleNames())},get theme(){return this._theme},get preset(){var e;return((e=this.theme)==null?void 0:e.preset)||{}},get options(){var e;return((e=this.theme)==null?void 0:e.options)||{}},get tokens(){return this._tokens},getTheme(){return this.theme},setTheme(e){this.update({theme:e}),U.emit("theme:change",e)},getPreset(){return this.preset},setPreset(e){this._theme=Vt(fe({},this.theme),{preset:e}),this._tokens=me.createTokens(e,this.defaults),this.clearLoadedStyleNames(),U.emit("preset:change",e),U.emit("theme:change",this.theme)},getOptions(){return this.options},setOptions(e){this._theme=Vt(fe({},this.theme),{options:e}),this.clearLoadedStyleNames(),U.emit("options:change",e),U.emit("theme:change",this.theme)},getLayerNames(){return[...this._layerNames]},setLayerNames(e){this._layerNames.add(e)},getLoadedStyleNames(){return this._loadedStyleNames},isStyleNameLoaded(e){return this._loadedStyleNames.has(e)},setLoadedStyleName(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames(){this._loadedStyleNames.clear()},getTokenValue(e){return me.getTokenValue(this.tokens,e,this.defaults)},getCommon(e="",t){return me.getCommon({name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getComponent(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPresetC(n)},getDirective(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPresetD(n)},getCustomPreset(e="",t,n,o){let r={name:e,preset:t,options:this.options,selector:n,params:o,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPreset(r)},getLayerOrderCSS(e=""){return me.getLayerOrder(e,this.options,{names:this.getLayerNames()},this.defaults)},transformCSS(e="",t,n="style",o){return me.transformCSS(e,t,o,n,this.options,{layerNames:this.setLayerNames.bind(this)},this.defaults)},getCommonStyleSheet(e="",t,n={}){return me.getCommonStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getStyleSheet(e,t,n={}){return me.getStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},onStyleMounted(e){this._loadingStyles.add(e)},onStyleUpdated(e){this._loadingStyles.add(e)},onStyleLoaded(e,{name:t}){this._loadingStyles.size&&(this._loadingStyles.delete(t),U.emit(`theme:${t}:load`,e),!this._loadingStyles.size&&U.emit("theme:load"))}},z={STARTS_WITH:"startsWith",CONTAINS:"contains",NOT_CONTAINS:"notContains",ENDS_WITH:"endsWith",EQUALS:"equals",NOT_EQUALS:"notEquals",LESS_THAN:"lt",LESS_THAN_OR_EQUAL_TO:"lte",GREATER_THAN:"gt",GREATER_THAN_OR_EQUAL_TO:"gte",DATE_IS:"dateIs",DATE_IS_NOT:"dateIsNot",DATE_BEFORE:"dateBefore",DATE_AFTER:"dateAfter"},br=`
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
`;function ot(e){"@babel/helpers - typeof";return ot=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ot(e)}function gn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function hn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?gn(Object(n),!0).forEach(function(o){vr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):gn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function vr(e,t,n){return(t=gr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function gr(e){var t=hr(e,"string");return ot(t)=="symbol"?t:t+""}function hr(e,t){if(ot(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ot(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function yr(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0;ln()&&ln().components?Vn(e):t?e():So(e)}var Sr=0;function _r(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},n=V(!1),o=V(e),r=V(null),a=or()?window.document:void 0,s=t.document,l=s===void 0?a:s,i=t.immediate,u=i===void 0?!0:i,d=t.manual,c=d===void 0?!1:d,p=t.name,m=p===void 0?"style_".concat(++Sr):p,f=t.id,y=f===void 0?void 0:f,g=t.media,_=g===void 0?void 0:g,k=t.nonce,N=k===void 0?void 0:k,v=t.first,w=v===void 0?!1:v,B=t.onMounted,H=B===void 0?void 0:B,ue=t.onUpdated,de=ue===void 0?void 0:ue,ce=t.onLoad,G=ce===void 0?void 0:ce,te=t.props,ne=te===void 0?{}:te,Y=function(){},oe=function(Se){var _e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(l){var pe=hn(hn({},ne),_e),le=pe.name||m,R=pe.id||y,je=pe.nonce||N;r.value=l.querySelector('style[data-primevue-style-id="'.concat(le,'"]'))||l.getElementById(R)||l.createElement("style"),r.value.isConnected||(o.value=Se||e,xt(r.value,{type:"text/css",id:R,media:_,nonce:je}),w?l.head.prepend(r.value):l.head.appendChild(r.value),rr(r.value,"data-primevue-style-id",le),xt(r.value,pe),r.value.onload=function(we){return G?.(we,{name:le})},H?.(le)),!n.value&&(Y=Re(o,function(we){r.value.textContent=we,de?.(le)},{immediate:!0}),n.value=!0)}},re=function(){!l||!n.value||(Y(),Zo(r.value)&&l.head.removeChild(r.value),n.value=!1,r.value=null)};return u&&!c&&yr(oe),{id:y,name:m,el:r,css:o,unload:re,load:oe,isLoaded:yo(n)}}function rt(e){"@babel/helpers - typeof";return rt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},rt(e)}var yn,Sn,_n,wn;function $n(e,t){return Pr(e)||kr(e,t)||$r(e,t)||wr()}function wr(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function $r(e,t){if(e){if(typeof e=="string")return kn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?kn(e,t):void 0}}function kn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function kr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,a,s,l=[],i=!0,u=!1;try{if(a=(n=n.call(e)).next,t!==0)for(;!(i=(o=a.call(n)).done)&&(l.push(o.value),l.length!==t);i=!0);}catch(d){u=!0,r=d}finally{try{if(!i&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function Pr(e){if(Array.isArray(e))return e}function Pn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function Mt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Pn(Object(n),!0).forEach(function(o){xr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Pn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function xr(e,t,n){return(t=Or(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Or(e){var t=Tr(e,"string");return rt(t)=="symbol"?t:t+""}function Tr(e,t){if(rt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(rt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function _t(e,t){return t||(t=e.slice(0)),Object.freeze(Object.defineProperties(e,{raw:{value:Object.freeze(t)}}))}var Cr=function(t){var n=t.dt;return`
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
`)},Ar={},Er={},D={name:"base",css:Cr,style:br,classes:Ar,inlineStyles:Er,load:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:function(a){return a},r=o(St(yn||(yn=_t(["",""])),t));return I(r)?_r(Qe(r),Mt({name:this.name},n)):{}},loadCSS:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};return this.load(this.css,t)},loadStyle:function(){var t=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"";return this.load(this.style,n,function(){var r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"";return L.transformCSS(n.name||t.name,"".concat(r).concat(St(Sn||(Sn=_t(["",""])),o)))})},getCommonTheme:function(t){return L.getCommon(this.name,t)},getComponentTheme:function(t){return L.getComponent(this.name,t)},getDirectiveTheme:function(t){return L.getDirective(this.name,t)},getPresetTheme:function(t,n,o){return L.getCustomPreset(this.name,t,n,o)},getLayerOrderThemeCSS:function(){return L.getLayerOrderCSS(this.name)},getStyleSheet:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(this.css){var o=se(this.css,{dt:Ae})||"",r=Qe(St(_n||(_n=_t(["","",""])),o,t)),a=Object.entries(n).reduce(function(s,l){var i=$n(l,2),u=i[0],d=i[1];return s.push("".concat(u,'="').concat(d,'"'))&&s},[]).join(" ");return I(r)?'<style type="text/css" data-primevue-style-id="'.concat(this.name,'" ').concat(a,">").concat(r,"</style>"):""}return""},getCommonThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return L.getCommonStyleSheet(this.name,t,n)},getThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=[L.getStyleSheet(this.name,t,n)];if(this.style){var r=this.name==="base"?"global-style":"".concat(this.name,"-style"),a=St(wn||(wn=_t(["",""])),se(this.style,{dt:Ae})),s=Qe(L.transformCSS(r,a)),l=Object.entries(n).reduce(function(i,u){var d=$n(u,2),c=d[0],p=d[1];return i.push("".concat(c,'="').concat(p,'"'))&&i},[]).join(" ");I(s)&&o.push('<style type="text/css" data-primevue-style-id="'.concat(r,'" ').concat(l,">").concat(s,"</style>"))}return o.join("")},extend:function(t){return Mt(Mt({},this),{},{css:void 0,style:void 0},t)}},Pe=zn();function at(e){"@babel/helpers - typeof";return at=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},at(e)}function xn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function wt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?xn(Object(n),!0).forEach(function(o){Lr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):xn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Lr(e,t,n){return(t=Nr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Nr(e){var t=jr(e,"string");return at(t)=="symbol"?t:t+""}function jr(e,t){if(at(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(at(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Ir={ripple:!1,inputStyle:null,inputVariant:null,locale:{startsWith:"Starts with",contains:"Contains",notContains:"Not contains",endsWith:"Ends with",equals:"Equals",notEquals:"Not equals",noFilter:"No Filter",lt:"Less than",lte:"Less than or equal to",gt:"Greater than",gte:"Greater than or equal to",dateIs:"Date is",dateIsNot:"Date is not",dateBefore:"Date is before",dateAfter:"Date is after",clear:"Clear",apply:"Apply",matchAll:"Match All",matchAny:"Match Any",addRule:"Add Rule",removeRule:"Remove Rule",accept:"Yes",reject:"No",choose:"Choose",upload:"Upload",cancel:"Cancel",completed:"Completed",pending:"Pending",fileSizeTypes:["B","KB","MB","GB","TB","PB","EB","ZB","YB"],dayNames:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],dayNamesShort:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],dayNamesMin:["Su","Mo","Tu","We","Th","Fr","Sa"],monthNames:["January","February","March","April","May","June","July","August","September","October","November","December"],monthNamesShort:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],chooseYear:"Choose Year",chooseMonth:"Choose Month",chooseDate:"Choose Date",prevDecade:"Previous Decade",nextDecade:"Next Decade",prevYear:"Previous Year",nextYear:"Next Year",prevMonth:"Previous Month",nextMonth:"Next Month",prevHour:"Previous Hour",nextHour:"Next Hour",prevMinute:"Previous Minute",nextMinute:"Next Minute",prevSecond:"Previous Second",nextSecond:"Next Second",am:"am",pm:"pm",today:"Today",weekHeader:"Wk",firstDayOfWeek:0,showMonthAfterYear:!1,dateFormat:"mm/dd/yy",weak:"Weak",medium:"Medium",strong:"Strong",passwordPrompt:"Enter a password",emptyFilterMessage:"No results found",searchMessage:"{0} results are available",selectionMessage:"{0} items selected",emptySelectionMessage:"No selected item",emptySearchMessage:"No results found",fileChosenMessage:"{0} files",noFileChosenMessage:"No file chosen",emptyMessage:"No available options",aria:{trueLabel:"True",falseLabel:"False",nullLabel:"Not Selected",star:"1 star",stars:"{star} stars",selectAll:"All items selected",unselectAll:"All items unselected",close:"Close",previous:"Previous",next:"Next",navigation:"Navigation",scrollTop:"Scroll Top",moveTop:"Move Top",moveUp:"Move Up",moveDown:"Move Down",moveBottom:"Move Bottom",moveToTarget:"Move to Target",moveToSource:"Move to Source",moveAllToTarget:"Move All to Target",moveAllToSource:"Move All to Source",pageLabel:"Page {page}",firstPageLabel:"First Page",lastPageLabel:"Last Page",nextPageLabel:"Next Page",prevPageLabel:"Previous Page",rowsPerPageLabel:"Rows per page",jumpToPageDropdownLabel:"Jump to Page Dropdown",jumpToPageInputLabel:"Jump to Page Input",selectRow:"Row Selected",unselectRow:"Row Unselected",expandRow:"Row Expanded",collapseRow:"Row Collapsed",showFilterMenu:"Show Filter Menu",hideFilterMenu:"Hide Filter Menu",filterOperator:"Filter Operator",filterConstraint:"Filter Constraint",editRow:"Row Edit",saveEdit:"Save Edit",cancelEdit:"Cancel Edit",listView:"List View",gridView:"Grid View",slide:"Slide",slideNumber:"{slideNumber}",zoomImage:"Zoom Image",zoomIn:"Zoom In",zoomOut:"Zoom Out",rotateRight:"Rotate Right",rotateLeft:"Rotate Left",listLabel:"Option List"}},filterMatchModeOptions:{text:[z.STARTS_WITH,z.CONTAINS,z.NOT_CONTAINS,z.ENDS_WITH,z.EQUALS,z.NOT_EQUALS],numeric:[z.EQUALS,z.NOT_EQUALS,z.LESS_THAN,z.LESS_THAN_OR_EQUAL_TO,z.GREATER_THAN,z.GREATER_THAN_OR_EQUAL_TO],date:[z.DATE_IS,z.DATE_IS_NOT,z.DATE_BEFORE,z.DATE_AFTER]},zIndex:{modal:1100,overlay:1e3,menu:1e3,tooltip:1100},theme:void 0,unstyled:!1,pt:void 0,ptOptions:{mergeSections:!0,mergeProps:!1},csp:{nonce:void 0}},Dr=Symbol();function Rr(e,t){var n={config:_o(t)};return e.config.globalProperties.$primevue=n,e.provide(Dr,n),Vr(),Mr(e,n),n}var Ve=[];function Vr(){U.clear(),Ve.forEach(function(e){return e?.()}),Ve=[]}function Mr(e,t){var n=V(!1),o=function(){var u;if(((u=t.config)===null||u===void 0?void 0:u.theme)!=="none"&&!L.isStyleNameLoaded("common")){var d,c,p=((d=D.getCommonTheme)===null||d===void 0?void 0:d.call(D))||{},m=p.primitive,f=p.semantic,y=p.global,g=p.style,_={nonce:(c=t.config)===null||c===void 0||(c=c.csp)===null||c===void 0?void 0:c.nonce};D.load(m?.css,wt({name:"primitive-variables"},_)),D.load(f?.css,wt({name:"semantic-variables"},_)),D.load(y?.css,wt({name:"global-variables"},_)),D.loadStyle(wt({name:"global-style"},_),g),L.setLoadedStyleName("common")}};U.on("theme:change",function(i){n.value||(e.config.globalProperties.$primevue.config.theme=i,n.value=!0)});var r=Re(t.config,function(i,u){Pe.emit("config:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!0}),a=Re(function(){return t.config.ripple},function(i,u){Pe.emit("config:ripple:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!0}),s=Re(function(){return t.config.theme},function(i,u){n.value||L.setTheme(i),t.config.unstyled||o(),n.value=!1,Pe.emit("config:theme:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!1}),l=Re(function(){return t.config.unstyled},function(i,u){!i&&t.config.theme&&o(),Pe.emit("config:unstyled:change",{newValue:i,oldValue:u})},{immediate:!0,deep:!0});Ve.push(r),Ve.push(a),Ve.push(s),Ve.push(l)}var Br={install:function(t,n){var o=zo(Ir,n);Rr(t,o)}};const Wr={install:e=>e.use(Br,{theme:"none"})};var ke={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(t){return this._loadedStyleNames.has(t)},setLoadedStyleName:function(t){this._loadedStyleNames.add(t)},deleteLoadedStyleName:function(t){this._loadedStyleNames.delete(t)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function Ur(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",t=wo();return"".concat(e).concat(t.replace("v-","").replaceAll("-","_"))}var On=D.extend({name:"common"});function it(e){"@babel/helpers - typeof";return it=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},it(e)}function zr(e){return ao(e)||Hr(e)||ro(e)||oo()}function Hr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function qe(e,t){return ao(e)||qr(e,t)||ro(e,t)||oo()}function oo(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ro(e,t){if(e){if(typeof e=="string")return Qt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Qt(e,t):void 0}}function Qt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function qr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,a,s,l=[],i=!0,u=!1;try{if(a=(n=n.call(e)).next,t===0){if(Object(n)!==n)return;i=!1}else for(;!(i=(o=a.call(n)).done)&&(l.push(o.value),l.length!==t);i=!0);}catch(d){u=!0,r=d}finally{try{if(!i&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function ao(e){if(Array.isArray(e))return e}function Tn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function x(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Tn(Object(n),!0).forEach(function(o){Ye(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Tn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ye(e,t,n){return(t=Kr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Kr(e){var t=Fr(e,"string");return it(t)=="symbol"?t:t+""}function Fr(e,t){if(it(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(it(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var nn={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(t){U.off("theme:change",this._loadCoreStyles),t||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(t,n){var o=this;U.off("theme:change",this._themeScopedListener),t?(this._loadScopedThemeStyles(t),this._themeScopedListener=function(){return o._loadScopedThemeStyles(t)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var t,n,o,r,a,s,l,i,u,d,c,p=(t=this.pt)===null||t===void 0?void 0:t._usept,m=p?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,f=p?(o=this.pt)===null||o===void 0||(o=o.value)===null||o===void 0?void 0:o[this.$.type.name]:this.pt;(r=f||m)===null||r===void 0||(r=r.hooks)===null||r===void 0||(a=r.onBeforeCreate)===null||a===void 0||a.call(r);var y=(s=this.$primevueConfig)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s._usept,g=y?(l=this.$primevue)===null||l===void 0||(l=l.config)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l.originalValue:void 0,_=y?(i=this.$primevue)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.pt)===null||i===void 0?void 0:i.value:(u=this.$primevue)===null||u===void 0||(u=u.config)===null||u===void 0?void 0:u.pt;(d=_||g)===null||d===void 0||(d=d[this.$.type.name])===null||d===void 0||(d=d.hooks)===null||d===void 0||(c=d.onBeforeCreate)===null||c===void 0||c.call(d),this.$attrSelector=Ur(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var t;this.rootEl=Fn(Ne(this.$el)?this.$el:(t=this.$el)===null||t===void 0?void 0:t.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=x({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(t){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(t)),o=this._useDefaultPT(this._getOptionValue,"hooks.".concat(t));n?.(),o?.()}},_mergeProps:function(t){for(var n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return Tt(t)?t.apply(void 0,o):J.apply(void 0,o)},_load:function(){ke.isStyleNameLoaded("base")||(D.loadCSS(this.$styleOptions),this._loadGlobalStyles(),ke.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var t,n;!ke.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(On.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),ke.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var t=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);I(t)&&D.load(t,x({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var t,n;if(!(this.isUnstyled||this.$theme==="none")){if(!L.isStyleNameLoaded("common")){var o,r,a=((o=this.$style)===null||o===void 0||(r=o.getCommonTheme)===null||r===void 0?void 0:r.call(o))||{},s=a.primitive,l=a.semantic,i=a.global,u=a.style;D.load(s?.css,x({name:"primitive-variables"},this.$styleOptions)),D.load(l?.css,x({name:"semantic-variables"},this.$styleOptions)),D.load(i?.css,x({name:"global-variables"},this.$styleOptions)),D.loadStyle(x({name:"global-style"},this.$styleOptions),u),L.setLoadedStyleName("common")}if(!L.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var d,c,p,m,f=((d=this.$style)===null||d===void 0||(c=d.getComponentTheme)===null||c===void 0?void 0:c.call(d))||{},y=f.css,g=f.style;(p=this.$style)===null||p===void 0||p.load(y,x({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(m=this.$style)===null||m===void 0||m.loadStyle(x({name:"".concat(this.$style.name,"-style")},this.$styleOptions),g),L.setLoadedStyleName(this.$style.name)}if(!L.isStyleNameLoaded("layer-order")){var _,k,N=(_=this.$style)===null||_===void 0||(k=_.getLayerOrderThemeCSS)===null||k===void 0?void 0:k.call(_);D.load(N,x({name:"layer-order",first:!0},this.$styleOptions)),L.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(t){var n,o,r,a=((n=this.$style)===null||n===void 0||(o=n.getPresetTheme)===null||o===void 0?void 0:o.call(n,t,"[".concat(this.$attrSelector,"]")))||{},s=a.css,l=(r=this.$style)===null||r===void 0?void 0:r.load(s,x({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=l.el},_unloadScopedThemeStyles:function(){var t;(t=this.scopedStyleEl)===null||t===void 0||(t=t.value)===null||t===void 0||t.remove()},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};ke.clearLoadedStyleNames(),U.on("theme:change",t)},_removeThemeListeners:function(){U.off("theme:change",this._loadCoreStyles),U.off("theme:change",this._load),U.off("theme:change",this._themeScopedListener)},_getHostInstance:function(t){return t?this.$options.hostName?t.$.type.name===this.$options.hostName?t:this._getHostInstance(t.$parentInstance):t.$parentInstance:void 0},_getPropValue:function(t){var n;return this[t]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[t])},_getOptionValue:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return tn(t,n,o)},_getPTValue:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,s=/./g.test(o)&&!!r[o.split(".")[0]],l=this._getPropValue("ptOptions")||((t=this.$primevueConfig)===null||t===void 0?void 0:t.ptOptions)||{},i=l.mergeSections,u=i===void 0?!0:i,d=l.mergeProps,c=d===void 0?!1:d,p=a?s?this._useGlobalPT(this._getPTClassValue,o,r):this._useDefaultPT(this._getPTClassValue,o,r):void 0,m=s?void 0:this._getPTSelf(n,this._getPTClassValue,o,x(x({},r),{},{global:p||{}})),f=this._getPTDatasets(o);return u||!u&&m?c?this._mergeProps(c,p,m,f):x(x(x({},p),m),f):x(x({},m),f)},_getPTSelf:function(){for(var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return J(this._usePT.apply(this,[this._getPT(t,this.$name)].concat(o)),this._usePT.apply(this,[this.$_attrsPT].concat(o)))},_getPTDatasets:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r="data-pc-",a=o==="root"&&I((t=this.pt)===null||t===void 0?void 0:t["data-pc-section"]);return o!=="transition"&&x(x({},o==="root"&&x(x(Ye({},"".concat(r,"name"),ve(a?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),a&&Ye({},"".concat(r,"extend"),ve(this.$.type.name))),{},Ye({},"".concat(this.$attrSelector),""))),{},Ye({},"".concat(r,"section"),ve(o)))},_getPTClassValue:function(){var t=this._getOptionValue.apply(this,arguments);return ee(t)||Wn(t)?{class:t}:t},_getPT:function(t){var n=this,o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,a=function(l){var i,u=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,d=r?r(l):l,c=ve(o),p=ve(n.$name);return(i=u?c!==p?d?.[c]:void 0:d?.[c])!==null&&i!==void 0?i:d};return t!=null&&t.hasOwnProperty("_usept")?{_usept:t._usept,originalValue:a(t.originalValue),value:a(t.value)}:a(t,!0)},_usePT:function(t,n,o,r){var a=function(y){return n(y,o,r)};if(t!=null&&t.hasOwnProperty("_usept")){var s,l=t._usept||((s=this.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},i=l.mergeSections,u=i===void 0?!0:i,d=l.mergeProps,c=d===void 0?!1:d,p=a(t.originalValue),m=a(t.value);return p===void 0&&m===void 0?void 0:ee(m)?m:ee(p)?p:u||!u&&m?c?this._mergeProps(c,p,m):x(x({},p),m):m}return a(t)},_useGlobalPT:function(t,n,o){return this._usePT(this.globalPT,t,n,o)},_useDefaultPT:function(t,n,o){return this._usePT(this.defaultPT,t,n,o)},ptm:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,t,x(x({},this.$params),n))},ptmi:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=J(this.$_attrsWithoutPT,this.ptm(n,o));return r?.hasOwnProperty("id")&&((t=r.id)!==null&&t!==void 0||(r.id=this.$id)),r},ptmo:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(t,n,x({instance:this},o),!1)},cx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,t,x(x({},this.$params),n))},sx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var r=this._getOptionValue(this.$style.inlineStyles,t,x(x({},this.$params),o)),a=this._getOptionValue(On.inlineStyles,t,x(x({},this.$params),o));return[a,r]}}},computed:{globalPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return se(o,{instance:n})})},defaultPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return n._getOptionValue(o,n.$name,x({},n.$params))||se(o,x({},n.$params))})},isUnstyled:function(){var t;return this.unstyled!==void 0?this.unstyled:(t=this.$primevueConfig)===null||t===void 0?void 0:t.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var t,n=Object.keys(((t=this.$.vnode)===null||t===void 0?void 0:t.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(o){var r=qe(o,1),a=r[0];return n?.includes(a)}))},$theme:function(){var t;return(t=this.$primevueConfig)===null||t===void 0?void 0:t.theme},$style:function(){return x(x({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var t;return{nonce:(t=this.$primevueConfig)===null||t===void 0||(t=t.csp)===null||t===void 0?void 0:t.nonce}},$primevueConfig:function(){var t;return(t=this.$primevue)===null||t===void 0?void 0:t.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var t=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:t,props:t?.$props,state:t?.$data,attrs:t?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=qe(t,1),o=n[0];return o?.startsWith("pt:")}).reduce(function(t,n){var o=qe(n,2),r=o[0],a=o[1],s=r.split(":"),l=zr(s),i=Qt(l).slice(1);return i?.reduce(function(u,d,c,p){return!u[d]&&(u[d]=c===p.length-1?a:{}),u[d]},t),t},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=qe(t,1),o=n[0];return!(o!=null&&o.startsWith("pt:"))}).reduce(function(t,n){var o=qe(n,2),r=o[0],a=o[1];return t[r]=a,t},{})}}},Gr=`
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
`,Yr=D.extend({name:"baseicon",css:Gr});function st(e){"@babel/helpers - typeof";return st=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},st(e)}function Cn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function An(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Cn(Object(n),!0).forEach(function(o){Qr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Cn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Qr(e,t,n){return(t=Zr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Zr(e){var t=Jr(e,"string");return st(t)=="symbol"?t:t+""}function Jr(e,t){if(st(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(st(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Xr={name:"BaseIcon",extends:nn,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:Yr,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var t=Le(this.label);return An(An({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:t?void 0:"img","aria-label":t?void 0:this.label,"aria-hidden":t})}}},io={name:"SpinnerIcon",extends:Xr};function ea(e){return ra(e)||oa(e)||na(e)||ta()}function ta(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function na(e,t){if(e){if(typeof e=="string")return Zt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Zt(e,t):void 0}}function oa(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function ra(e){if(Array.isArray(e))return Zt(e)}function Zt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function aa(e,t,n,o,r,a){return O(),E("svg",J({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},e.pti()),ea(t[0]||(t[0]=[M("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}io.render=aa;var ia=`
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
`,sa={root:function(t){var n=t.props,o=t.instance;return["p-badge p-component",{"p-badge-circle":I(n.value)&&String(n.value).length===1,"p-badge-dot":Le(n.value)&&!o.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},la=D.extend({name:"badge",style:ia,classes:sa}),ua={name:"BaseBadge",extends:nn,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:la,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function lt(e){"@babel/helpers - typeof";return lt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},lt(e)}function En(e,t,n){return(t=da(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function da(e){var t=ca(e,"string");return lt(t)=="symbol"?t:t+""}function ca(e,t){if(lt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(lt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var so={name:"Badge",extends:ua,inheritAttrs:!1,computed:{dataP:function(){return Ze(En(En({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},pa=["data-p"];function ma(e,t,n,o,r,a){return O(),E("span",J({class:e.cx("root"),"data-p":a.dataP},e.ptmi("root")),[Fe(e.$slots,"default",{},function(){return[Xe(X(e.value),1)]})],16,pa)}so.render=ma;function ut(e){"@babel/helpers - typeof";return ut=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ut(e)}function Ln(e,t){return ga(e)||va(e,t)||ba(e,t)||fa()}function fa(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ba(e,t){if(e){if(typeof e=="string")return Nn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Nn(e,t):void 0}}function Nn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function va(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,a,s,l=[],i=!0,u=!1;try{if(a=(n=n.call(e)).next,t!==0)for(;!(i=(o=a.call(n)).done)&&(l.push(o.value),l.length!==t);i=!0);}catch(d){u=!0,r=d}finally{try{if(!i&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function ga(e){if(Array.isArray(e))return e}function jn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function T(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?jn(Object(n),!0).forEach(function(o){Jt(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):jn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Jt(e,t,n){return(t=ha(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function ha(e){var t=ya(e,"string");return ut(t)=="symbol"?t:t+""}function ya(e,t){if(ut(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ut(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var $={_getMeta:function(){return[ge(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],se(ge(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(t,n){var o,r,a;return(o=(t==null||(r=t.instance)===null||r===void 0?void 0:r.$primevue)||(n==null||(a=n.ctx)===null||a===void 0||(a=a.appContext)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.globalProperties)===null||a===void 0?void 0:a.$primevue))===null||o===void 0?void 0:o.config},_getOptionValue:tn,_getPTValue:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},a=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",s=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},l=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,i=function(){var k=$._getOptionValue.apply($,arguments);return ee(k)||Wn(k)?{class:k}:k},u=((t=o.binding)===null||t===void 0||(t=t.value)===null||t===void 0?void 0:t.ptOptions)||((n=o.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},d=u.mergeSections,c=d===void 0?!0:d,p=u.mergeProps,m=p===void 0?!1:p,f=l?$._useDefaultPT(o,o.defaultPT(),i,a,s):void 0,y=$._usePT(o,$._getPT(r,o.$name),i,a,T(T({},s),{},{global:f||{}})),g=$._getPTDatasets(o,a);return c||!c&&y?m?$._mergeProps(o,m,f,y,g):T(T(T({},f),y),g):T(T({},y),g)},_getPTDatasets:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o="data-pc-";return T(T({},n==="root"&&Jt({},"".concat(o,"name"),ve(t.$name))),{},Jt({},"".concat(o,"section"),ve(n)))},_getPT:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,r=function(s){var l,i=o?o(s):s,u=ve(n);return(l=i?.[u])!==null&&l!==void 0?l:i};return t&&Object.hasOwn(t,"_usept")?{_usept:t._usept,originalValue:r(t.originalValue),value:r(t.value)}:r(t)},_usePT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0,s=function(g){return o(g,r,a)};if(n&&Object.hasOwn(n,"_usept")){var l,i=n._usept||((l=t.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},u=i.mergeSections,d=u===void 0?!0:u,c=i.mergeProps,p=c===void 0?!1:c,m=s(n.originalValue),f=s(n.value);return m===void 0&&f===void 0?void 0:ee(f)?f:ee(m)?m:d||!d&&f?p?$._mergeProps(t,p,m,f):T(T({},m),f):f}return s(n)},_useDefaultPT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0;return $._usePT(t,n,o,r,a)},_loadStyles:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,a=$._getConfig(o,r),s={nonce:a==null||(t=a.csp)===null||t===void 0?void 0:t.nonce};$._loadCoreStyles(n,s),$._loadThemeStyles(n,s),$._loadScopedThemeStyles(n,s),$._removeThemeListeners(n),n.$loadStyles=function(){return $._loadThemeStyles(n,s)},$._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0;if(!ke.isStyleNameLoaded((t=o.$style)===null||t===void 0?void 0:t.name)&&(n=o.$style)!==null&&n!==void 0&&n.name){var a;D.loadCSS(r),(a=o.$style)===null||a===void 0||a.loadCSS(r),ke.setLoadedStyleName(o.$style.name)}},_loadThemeStyles:function(){var t,n,o,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},a=arguments.length>1?arguments[1]:void 0;if(!(r!=null&&r.isUnstyled()||(r==null||(t=r.theme)===null||t===void 0?void 0:t.call(r))==="none")){if(!L.isStyleNameLoaded("common")){var s,l,i=((s=r.$style)===null||s===void 0||(l=s.getCommonTheme)===null||l===void 0?void 0:l.call(s))||{},u=i.primitive,d=i.semantic,c=i.global,p=i.style;D.load(u?.css,T({name:"primitive-variables"},a)),D.load(d?.css,T({name:"semantic-variables"},a)),D.load(c?.css,T({name:"global-variables"},a)),D.loadStyle(T({name:"global-style"},a),p),L.setLoadedStyleName("common")}if(!L.isStyleNameLoaded((n=r.$style)===null||n===void 0?void 0:n.name)&&(o=r.$style)!==null&&o!==void 0&&o.name){var m,f,y,g,_=((m=r.$style)===null||m===void 0||(f=m.getDirectiveTheme)===null||f===void 0?void 0:f.call(m))||{},k=_.css,N=_.style;(y=r.$style)===null||y===void 0||y.load(k,T({name:"".concat(r.$style.name,"-variables")},a)),(g=r.$style)===null||g===void 0||g.loadStyle(T({name:"".concat(r.$style.name,"-style")},a),N),L.setLoadedStyleName(r.$style.name)}if(!L.isStyleNameLoaded("layer-order")){var v,w,B=(v=r.$style)===null||v===void 0||(w=v.getLayerOrderThemeCSS)===null||w===void 0?void 0:w.call(v);D.load(B,T({name:"layer-order",first:!0},a)),L.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=t.preset();if(o&&t.$attrSelector){var r,a,s,l=((r=t.$style)===null||r===void 0||(a=r.getPresetTheme)===null||a===void 0?void 0:a.call(r,o,"[".concat(t.$attrSelector,"]")))||{},i=l.css,u=(s=t.$style)===null||s===void 0?void 0:s.load(i,T({name:"".concat(t.$attrSelector,"-").concat(t.$style.name)},n));t.scopedStyleEl=u.el}},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};ke.clearLoadedStyleNames(),U.on("theme:change",t)},_removeThemeListeners:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};U.off("theme:change",t.$loadStyles),t.$loadStyles=void 0},_hook:function(t,n,o,r,a,s){var l,i,u="on".concat(Ho(n)),d=$._getConfig(r,a),c=o?.$instance,p=$._usePT(c,$._getPT(r==null||(l=r.value)===null||l===void 0?void 0:l.pt,t),$._getOptionValue,"hooks.".concat(u)),m=$._useDefaultPT(c,d==null||(i=d.pt)===null||i===void 0||(i=i.directives)===null||i===void 0?void 0:i[t],$._getOptionValue,"hooks.".concat(u)),f={el:o,binding:r,vnode:a,prevVnode:s};p?.(c,f),m?.(c,f)},_mergeProps:function(){for(var t=arguments.length>1?arguments[1]:void 0,n=arguments.length,o=new Array(n>2?n-2:0),r=2;r<n;r++)o[r-2]=arguments[r];return Tt(t)?t.apply(void 0,o):J.apply(void 0,o)},_extend:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=function(l,i,u,d,c){var p,m,f,y;i._$instances=i._$instances||{};var g=$._getConfig(u,d),_=i._$instances[t]||{},k=Le(_)?T(T({},n),n?.methods):{};i._$instances[t]=T(T({},_),{},{$name:t,$host:i,$binding:u,$modifiers:u?.modifiers,$value:u?.value,$el:_.$el||i||void 0,$style:T({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:g,$attrSelector:(p=i.$pd)===null||p===void 0||(p=p[t])===null||p===void 0?void 0:p.attrSelector,defaultPT:function(){return $._getPT(g?.pt,void 0,function(v){var w;return v==null||(w=v.directives)===null||w===void 0?void 0:w[t]})},isUnstyled:function(){var v,w;return((v=i._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.unstyled)!==void 0?(w=i._$instances[t])===null||w===void 0||(w=w.$binding)===null||w===void 0||(w=w.value)===null||w===void 0?void 0:w.unstyled:g?.unstyled},theme:function(){var v;return(v=i._$instances[t])===null||v===void 0||(v=v.$primevueConfig)===null||v===void 0?void 0:v.theme},preset:function(){var v;return(v=i._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.dt},ptm:function(){var v,w=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",B=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return $._getPTValue(i._$instances[t],(v=i._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.pt,w,T({},B))},ptmo:function(){var v=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},w=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",B=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return $._getPTValue(i._$instances[t],v,w,B,!1)},cx:function(){var v,w,B=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",H=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(v=i._$instances[t])!==null&&v!==void 0&&v.isUnstyled()?void 0:$._getOptionValue((w=i._$instances[t])===null||w===void 0||(w=w.$style)===null||w===void 0?void 0:w.classes,B,T({},H))},sx:function(){var v,w=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",B=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,H=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return B?$._getOptionValue((v=i._$instances[t])===null||v===void 0||(v=v.$style)===null||v===void 0?void 0:v.inlineStyles,w,T({},H)):void 0}},k),i.$instance=i._$instances[t],(m=(f=i.$instance)[l])===null||m===void 0||m.call(f,i,u,d,c),i["$".concat(t)]=i.$instance,$._hook(t,l,i,u,d,c),i.$pd||(i.$pd={}),i.$pd[t]=T(T({},(y=i.$pd)===null||y===void 0?void 0:y[t]),{},{name:t,instance:i._$instances[t]})},r=function(l){var i,u,d,c=l._$instances[t],p=c?.watch,m=function(g){var _,k=g.newValue,N=g.oldValue;return p==null||(_=p.config)===null||_===void 0?void 0:_.call(c,k,N)},f=function(g){var _,k=g.newValue,N=g.oldValue;return p==null||(_=p["config.ripple"])===null||_===void 0?void 0:_.call(c,k,N)};c.$watchersCallback={config:m,"config.ripple":f},p==null||(i=p.config)===null||i===void 0||i.call(c,c?.$primevueConfig),Pe.on("config:change",m),p==null||(u=p["config.ripple"])===null||u===void 0||u.call(c,c==null||(d=c.$primevueConfig)===null||d===void 0?void 0:d.ripple),Pe.on("config:ripple:change",f)},a=function(l){var i=l._$instances[t].$watchersCallback;i&&(Pe.off("config:change",i.config),Pe.off("config:ripple:change",i["config.ripple"]),l._$instances[t].$watchersCallback=void 0)};return{created:function(l,i,u,d){l.$pd||(l.$pd={}),l.$pd[t]={name:t,attrSelector:ar("pd")},o("created",l,i,u,d)},beforeMount:function(l,i,u,d){var c;$._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,i,u),o("beforeMount",l,i,u,d),r(l)},mounted:function(l,i,u,d){var c;$._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,i,u),o("mounted",l,i,u,d)},beforeUpdate:function(l,i,u,d){o("beforeUpdate",l,i,u,d)},updated:function(l,i,u,d){var c;$._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,i,u),o("updated",l,i,u,d)},beforeUnmount:function(l,i,u,d){var c;a(l),$._removeThemeListeners((c=l.$pd[t])===null||c===void 0?void 0:c.instance),o("beforeUnmount",l,i,u,d)},unmounted:function(l,i,u,d){var c;(c=l.$pd[t])===null||c===void 0||(c=c.instance)===null||c===void 0||(c=c.scopedStyleEl)===null||c===void 0||(c=c.value)===null||c===void 0||c.remove(),o("unmounted",l,i,u,d)}}},extend:function(){var t=$._getMeta.apply($,arguments),n=Ln(t,2),o=n[0],r=n[1];return T({extend:function(){var s=$._getMeta.apply($,arguments),l=Ln(s,2),i=l[0],u=l[1];return $.extend(i,T(T(T({},r),r?.methods),u))}},$._extend(o,r))}},Sa=`
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
`,_a={root:"p-ink"},wa=D.extend({name:"ripple-directive",style:Sa,classes:_a}),$a=$.extend({style:wa});function dt(e){"@babel/helpers - typeof";return dt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},dt(e)}function ka(e){return Ta(e)||Oa(e)||xa(e)||Pa()}function Pa(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function xa(e,t){if(e){if(typeof e=="string")return Xt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Xt(e,t):void 0}}function Oa(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function Ta(e){if(Array.isArray(e))return Xt(e)}function Xt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function In(e,t,n){return(t=Ca(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Ca(e){var t=Aa(e,"string");return dt(t)=="symbol"?t:t+""}function Aa(e,t){if(dt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(dt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Ea=$a.extend("ripple",{watch:{"config.ripple":function(t){t?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(t){this.remove(t)},timeout:void 0,methods:{bindEvents:function(t){t.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(t){t.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(t){var n=this.getInk(t);n||(n=Jo("span",In(In({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),t.appendChild(n),this.$el=n)},remove:function(t){var n=this.getInk(t);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(t),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(t){var n=this,o=t.currentTarget,r=this.getInk(o);if(!(!r||getComputedStyle(r,null).display==="none")){if(!this.isUnstyled()&&Je(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"),!mn(r)&&!fn(r)){var a=Math.max(Qo(o),nr(o));r.style.height=a+"px",r.style.width=a+"px"}var s=tr(o),l=t.pageX-s.left+document.body.scrollTop-fn(r)/2,i=t.pageY-s.top+document.body.scrollLeft-mn(r)/2;r.style.top=i+"px",r.style.left=l+"px",!this.isUnstyled()&&qt(r,"p-ink-active"),r.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){r&&(!n.isUnstyled()&&Je(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(t){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&Je(t.currentTarget,"p-ink-active"),t.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(t){return t&&t.children?ka(t.children).find(function(n){return er(n,"data-pc-name")==="ripple"}):void 0}}}),La=`
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
`;function ct(e){"@babel/helpers - typeof";return ct=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ct(e)}function be(e,t,n){return(t=Na(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Na(e){var t=ja(e,"string");return ct(t)=="symbol"?t:t+""}function ja(e,t){if(ct(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ct(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Ia={root:function(t){var n=t.instance,o=t.props;return["p-button p-component",be(be(be(be(be(be(be(be(be({"p-button-icon-only":n.hasIcon&&!o.label&&!o.badge,"p-button-vertical":(o.iconPos==="top"||o.iconPos==="bottom")&&o.label,"p-button-loading":o.loading,"p-button-link":o.link||o.variant==="link"},"p-button-".concat(o.severity),o.severity),"p-button-raised",o.raised),"p-button-rounded",o.rounded),"p-button-text",o.text||o.variant==="text"),"p-button-outlined",o.outlined||o.variant==="outlined"),"p-button-sm",o.size==="small"),"p-button-lg",o.size==="large"),"p-button-plain",o.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(t){var n=t.props;return["p-button-icon",be({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},Da=D.extend({name:"button",style:La,classes:Ia}),Ra={name:"BaseButton",extends:nn,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:Da,provide:function(){return{$pcButton:this,$parentInstance:this}}};function pt(e){"@babel/helpers - typeof";return pt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},pt(e)}function Z(e,t,n){return(t=Va(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Va(e){var t=Ma(e,"string");return pt(t)=="symbol"?t:t+""}function Ma(e,t){if(pt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(pt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var We={name:"Button",extends:Ra,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(t){var n=t==="root"?this.ptmi:this.ptm;return n(t,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return J(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return Le(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return Ze(Z(Z(Z(Z(Z(Z(Z(Z(Z(Z({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return Ze(Z(Z({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return Ze(Z(Z({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:io,Badge:so},directives:{ripple:Ea}},Ba=["data-p"],Wa=["data-p"];function Ua(e,t,n,o,r,a){var s=Ut("SpinnerIcon"),l=Ut("Badge"),i=$o("ripple");return e.asChild?Fe(e.$slots,"default",{key:1,class:Te(e.cx("root")),a11yAttrs:a.a11yAttrs}):ko((O(),Me(Po(e.as),J({key:0,class:e.cx("root"),"data-p":a.dataP},a.attrs),{default:Be(function(){return[Fe(e.$slots,"default",{},function(){return[e.loading?Fe(e.$slots,"loadingicon",J({key:0,class:[e.cx("loadingIcon"),e.cx("icon")]},e.ptm("loadingIcon")),function(){return[e.loadingIcon?(O(),E("span",J({key:0,class:[e.cx("loadingIcon"),e.cx("icon"),e.loadingIcon]},e.ptm("loadingIcon")),null,16)):(O(),Me(s,J({key:1,class:[e.cx("loadingIcon"),e.cx("icon")],spin:""},e.ptm("loadingIcon")),null,16,["class"]))]}):Fe(e.$slots,"icon",J({key:1,class:[e.cx("icon")]},e.ptm("icon")),function(){return[e.icon?(O(),E("span",J({key:0,class:[e.cx("icon"),e.icon,e.iconClass],"data-p":a.dataIconP},e.ptm("icon")),null,16,Ba)):F("",!0)]}),e.label?(O(),E("span",J({key:2,class:e.cx("label")},e.ptm("label"),{"data-p":a.dataLabelP}),X(e.label),17,Wa)):F("",!0),e.badge?(O(),Me(l,{key:3,value:e.badge,class:Te(e.badgeClass),severity:e.badgeSeverity,unstyled:e.unstyled,pt:e.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):F("",!0)]})]}),_:3},16,["class","data-p"])),[[i]])}We.render=Ua;const lo=Symbol("host_api"),uo=Symbol("axios"),co=Symbol("proxy"),za=Symbol("config"),Ha=Symbol("on_subscription");function qa(){const e=en(lo);if(!e)throw new Error("HostApi not provided");return e}function Ka(){const e=en(uo);if(!e)throw new Error("ProxyApiInstance not provided");return e}function Fa(){const e=en(co);if(!e)throw new Error("WIPPY_INSTANCE not provided");return e}const ds={changeset:"keeper.changeset",git:"keeper.git",version:"registry:version"};async function Ga(e){const{data:t}=await e.post("/api/v1/keeper/events/subscribe",{});return t}async function Ya(e){const{data:t}=await e.post("/api/v1/keeper/events/unsubscribe",{});return t}const on="keeper.events.muted",Ue=V(!1),Ct=V(localStorage.getItem(on)==="1"),$t=V(!1),mt=V(null);function po(e){return e?.response?.data?.error||e?.message||"request failed"}async function mo(e,t=!1){if(!(Ct.value||$t.value)&&!(Ue.value&&!t)){$t.value=!0;try{const n=await Ga(e);Ue.value=n.subscribed===!0,mt.value=null}catch(n){Ue.value=!1,mt.value=po(n)}finally{$t.value=!1}}}async function Qa(e){if(Ct.value=!0,localStorage.setItem(on,"1"),!!Ue.value)try{await Ya(e),Ue.value=!1,mt.value=null}catch(t){mt.value=po(t)}}async function Za(e){Ct.value=!1,localStorage.removeItem(on),await mo(e,!0)}function Ja(){return{subscribed:Ue,muted:Ct,pending:$t,error:mt,ensureSubscribed:mo,mute:Qa,unmute:Za}}async function cs(e){const{data:t}=await e.get("/api/v1/keeper/registry/namespaces");return t}async function ps(e,t={}){const n={limit:t.limit||200,offset:t.offset||0};t.namespace&&(n.namespace=t.namespace),t.kind&&(n.kind=t.kind),t.metaType&&(n["meta.type"]=t.metaType),t.query&&(n.q=t.query);const{data:o}=await e.get("/api/v1/keeper/registry/entries",{params:n});return o}async function ms(e,t){const{data:n}=await e.get("/api/v1/keeper/registry/entry",{params:{id:t}});return n}async function fs(e,t,n){const{data:o}=await e.put("/api/v1/keeper/registry/entry",n,{params:{id:t}});return o}async function bs(e,t){const n={};t&&(n.namespace=t);const{data:o}=await e.get("/api/v1/keeper/state/graph",{params:n});return o}async function vs(e){const{data:t}=await e.get("/api/v1/keeper/env/list");return t}async function gs(e,t,n){const{data:o}=await e.post("/api/v1/keeper/env/set",{key:t,value:n});return o}async function hs(e){const{data:t}=await e.get("/api/v1/keeper/sync/state");return t}async function ys(e){const{data:t}=await e.get("/api/v1/keeper/sync/config");return t}async function Ss(e,t){const{data:n}=await e.put("/api/v1/keeper/sync/config",{managed_namespaces:t});return n}async function _s(e){const{data:t}=await e.post("/api/v1/keeper/sync/download");return t}async function ws(e){const{data:t}=await e.post("/api/v1/keeper/sync/upload");return t}async function $s(e){const{data:t}=await e.post("/api/v1/keeper/sync/undo");return t}async function ks(e){const{data:t}=await e.post("/api/v1/keeper/sync/redo");return t}const Bt={"ns.definition":"var(--p-info-500)","ns.requirement":"var(--p-warn-500)","ns.dependency":"var(--p-accent-400)","http.service":"var(--p-success-500)","http.router":"var(--p-success-500)","http.endpoint":"var(--p-info-500)","http.static":"var(--p-info-500)","function.lua":"var(--p-warn-500)","library.lua":"var(--p-warn-500)","process.lua":"var(--p-warn-500)","registry.entry":"var(--p-accent-500)","db.sql.sqlite":"var(--p-accent-500)","fs.directory":"var(--p-text-muted-color)","fs.embed":"var(--p-text-muted-color)","process.host":"var(--p-info-500)","store.memory":"var(--p-accent-500)","store.sql":"var(--p-accent-500)","env.variable":"var(--p-text-muted-color)","env.composite":"var(--p-text-muted-color)","env.file":"var(--p-text-muted-color)","env.os":"var(--p-text-muted-color)","env.memory":"var(--p-text-muted-color)","security.policy":"var(--p-danger-500)","view.page":"var(--p-info-500)","view.component":"var(--p-info-500)","queue.memory":"var(--p-accent-500)","queue.consumer":"var(--p-accent-500)","template.set":"var(--p-warn-500)",contract:"var(--p-accent-400)","agent.gen1":"var(--p-warn-500)","agent.trait":"var(--p-warn-500)","llm.model":"var(--p-accent-500)",tool:"var(--p-info-500)"},Wt={"ns.definition":"tabler:package","ns.requirement":"tabler:plug","ns.dependency":"tabler:link","http.service":"tabler:server","http.router":"tabler:route","http.endpoint":"tabler:api","http.static":"tabler:file","function.lua":"tabler:code","library.lua":"tabler:book","process.lua":"tabler:code","registry.entry":"tabler:database","db.sql.sqlite":"tabler:database","fs.directory":"tabler:folder","fs.embed":"tabler:folder","process.host":"tabler:cpu","store.memory":"tabler:database","store.sql":"tabler:database","env.variable":"tabler:variable","env.composite":"tabler:variable","env.file":"tabler:variable","env.os":"tabler:variable","env.memory":"tabler:variable","security.policy":"tabler:shield-check","view.page":"tabler:browser","view.component":"tabler:components","queue.memory":"tabler:list","queue.consumer":"tabler:player-play","template.set":"tabler:template",contract:"tabler:file-certificate","agent.gen1":"tabler:robot","agent.trait":"tabler:sparkles","llm.model":"tabler:brain",tool:"tabler:tool"};function kt(e,t){return t&&Bt[t]?Bt[t]:Bt[e]||"var(--p-text-muted-color)"}function fo(e,t){return t&&Wt[t]?Wt[t]:Wt[e]||"tabler:circle"}async function Ps(e,t=100,n=0){const{data:o}=await e.get("/api/v1/sessions",{params:{limit:t,offset:n}});return o}async function xs(e,t){const{data:n}=await e.get("/api/v1/sessions/get",{params:{session_id:t}});return n}async function Os(e,t,n=50,o=""){const{data:r}=await e.get("/api/v1/sessions/messages",{params:{session_id:t,limit:n,cursor:o}});return r}function Ts(e){return!e||e===0?"0":e>=1e6?(e/1e6).toFixed(1)+"M":e>=1e3?(e/1e3).toFixed(1)+"K":e.toString()}function Dn(e){if(!e)return"";let t;typeof e=="number"?e>1e15?t=e/1e6:e>1e12?t=e/1e3:e>1e10?t=e:t=e*1e3:t=new Date(e).getTime();const n=new Date(t);if(isNaN(n.getTime()))return"";const r=Math.floor((new Date().getTime()-n.getTime())/1e3);if(r<60)return"just now";const a=Math.floor(r/60);if(a<60)return`${a}m ago`;const s=Math.floor(a/60);if(s<24)return`${s}h ago`;const l=Math.floor(s/24);if(l<30)return`${l}d ago`;const i=Math.floor(l/30);return i<12?`${i}mo ago`:`${Math.floor(i/12)}y ago`}function Cs(e){return e?new Date(typeof e=="number"?e*1e3:e).toLocaleString():"N/A"}const Xa={key:0,class:"status-dropdown"},ei=["onClick"],ti={key:0,class:"plugin-tag",title:"Provided by a registered plugin"},ni=Ee({__name:"AppNavDropdown",props:{icon:{},label:{},items:{},open:{type:Boolean},active:{type:Boolean},currentName:{},wrapClass:{}},emits:["toggle","navigate"],setup(e,{emit:t}){const n=t;function o(r){n("navigate",r)}return(r,a)=>(O(),E("div",{class:Te(["relative",e.wrapClass])},[j(C(We),{variant:"text",class:Te(["k-btn-nav relative !gap-1.5",{"k-btn-active":e.active}]),onClick:a[0]||(a[0]=s=>n("toggle"))},{default:Be(()=>[j(C(K),{icon:e.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Xe(" "+X(e.label)+" ",1),j(C(K),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.5"}})]),_:1},8,["class"]),e.open?(O(),E("div",Xa,[(O(!0),E(et,null,tt(e.items,s=>(O(),E("button",{key:s.name,class:Te(["status-item",{"status-item--active":e.currentName===s.name}]),onClick:l=>o(s.path)},[j(C(K),{icon:s.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Xe(" "+X(s.label)+" ",1),s.name.startsWith("plugin:")?(O(),E("span",ti,"plugin")):F("",!0)],10,ei))),128))])):F("",!0)],2))}}),rn=(e,t)=>{const n=e.__vccOpts||e;for(const[o,r]of t)n[o]=r;return n},Ke=rn(ni,[["__scopeId","data-v-6d403115"]]),oi={class:"truncate",style:{"max-width":"80px"}},ri={key:1,class:"relative agent-dropdown-wrap"},ai={key:0,class:"agent-dropdown"},ii=["onClick"],si={class:"agent-item-copy"},li={class:"agent-item-title"},ui={key:0,class:"agent-item-comment"},di=Ee({__name:"AppAgentLauncher",props:{agents:{},open:{type:Boolean}},emits:["toggle","start"],setup(e,{emit:t}){const n=t;return(o,r)=>e.agents.length===1?(O(),E("button",{key:0,class:"ask-btn",onClick:r[0]||(r[0]=a=>n("start",e.agents[0].start_token))},[j(C(K),{icon:e.agents[0].icon||"tabler:message-bolt",class:"w-3.5 h-3.5"},null,8,["icon"]),M("span",oi,X(e.agents[0].title||"Ask"),1)])):e.agents.length>1?(O(),E("div",ri,[M("button",{class:"ask-btn",onClick:r[1]||(r[1]=a=>n("toggle"))},[j(C(K),{icon:"tabler:message-bolt",class:"w-3.5 h-3.5"}),r[2]||(r[2]=Xe(" Ask ",-1)),j(C(K),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.6"}})]),e.open?(O(),E("div",ai,[(O(!0),E(et,null,tt(e.agents,a=>(O(),E("button",{key:a.id,class:"agent-item",onClick:s=>n("start",a.start_token)},[j(C(K),{icon:a.icon||"tabler:robot",class:"agent-item-icon"},null,8,["icon"]),M("span",si,[M("span",li,X(a.title||a.id),1),a.comment?(O(),E("span",ui,X(a.comment),1)):F("",!0)])],8,ii))),128))])):F("",!0)])):F("",!0)}}),ci=rn(di,[["__scopeId","data-v-eeb14e8e"]]),pi={key:0,class:"flex items-center gap-1.5 text-xs pl-2",style:{color:"var(--p-text-muted-color)","border-left":"1px solid var(--p-content-border-color)"}},mi={class:"truncate max-w-[100px]"},fi=Ee({__name:"AppUserChip",props:{user:{}},emits:["logout"],setup(e,{emit:t}){const n=t;return(o,r)=>e.user?(O(),E("div",pi,[M("span",mi,X(e.user.full_name||e.user.email),1),j(C(We),{class:"k-btn-icon !w-6 !h-6 !p-0 !rounded-full",title:"Logout",onClick:r[0]||(r[0]=a=>n("logout"))},{default:Be(()=>[j(C(K),{icon:"tabler:logout",class:"w-3 h-3"})]),_:1})])):F("",!0)}}),bi={class:"search-modal"},vi={class:"search-header"},gi=["value"],hi={key:0,class:"search-results"},yi=["onClick"],Si={class:"flex-1 min-w-0"},_i={class:"text-[11px] font-mono truncate",style:{color:"var(--p-text-color)"}},wi={key:0,class:"text-[9px] truncate",style:{color:"var(--p-text-muted-color)"}},$i={key:1,class:"search-empty"},ki={key:2,class:"search-hints"},Pi=["onClick"],xi={class:"text-[10px] font-mono",style:{color:"var(--p-primary-color)"}},Oi={class:"text-[10px]",style:{color:"var(--p-text-muted-color)"}},Ti=Ee({__name:"AppGlobalSearch",props:{open:{type:Boolean},query:{},results:{},loading:{type:Boolean},hints:{}},emits:["update:query","close","search-input","select","apply-hint"],setup(e,{emit:t}){const n=t;function o(r){r.length>0&&n("select",r[0])}return(r,a)=>(O(),Me(xo,{to:"body"},[e.open?(O(),E("div",{key:0,class:"search-overlay",onClick:a[3]||(a[3]=Oo(s=>n("close"),["self"]))},[M("div",bi,[M("div",vi,[j(C(K),{icon:"tabler:search",class:"w-4 h-4 shrink-0",style:{color:"var(--p-text-muted-color)"}}),M("input",{value:e.query,onInput:a[0]||(a[0]=s=>{n("update:query",s.target.value),n("search-input")}),onKeydown:[a[1]||(a[1]=un(s=>n("close"),["escape"])),a[2]||(a[2]=un(s=>o(e.results),["enter"]))],class:"global-search-input",placeholder:"Search entries, functions, configs...",autofocus:""},null,40,gi),e.loading?(O(),Me(C(K),{key:0,icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin",style:{color:"var(--p-primary-color)"}})):F("",!0),a[4]||(a[4]=M("kbd",{class:"search-kbd"},"Esc",-1))]),e.results.length>0?(O(),E("div",hi,[(O(!0),E(et,null,tt(e.results,s=>(O(),E("div",{key:s.id,class:"search-item",onClick:l=>n("select",s)},[j(C(K),{icon:s.icon||C(fo)(s.kind),class:"w-3 h-3 shrink-0",style:zt({color:s.color||C(kt)(s.kind)})},null,8,["icon","style"]),M("div",Si,[M("div",_i,X(s.id),1),s.snippet?(O(),E("div",wi,X(s.snippet),1)):F("",!0)]),M("span",{class:"text-[8px] px-1 rounded",style:zt({color:s.color||C(kt)(s.kind),background:`color-mix(in srgb, ${s.color||C(kt)(s.kind)} 12%, transparent)`})},X(s.kind),5)],8,yi))),128))])):e.query&&!e.loading?(O(),E("div",$i,"No results")):e.query?F("",!0):(O(),E("div",ki,[(O(!0),E(et,null,tt(e.hints,s=>(O(),E("div",{key:s.prefix,class:"search-hint",onClick:l=>n("apply-hint",s.prefix)},[j(C(K),{icon:s.icon,class:"w-3 h-3 shrink-0",style:{color:"var(--p-text-muted-color)"}},null,8,["icon"]),M("span",xi,X(s.prefix||"*"),1),M("span",Oi,X(s.desc),1)],8,Pi))),128))]))])])):F("",!0)]))}}),Ci={class:"h-full flex flex-col"},Ai={class:"shrink-0 h-10 flex items-center px-3 gap-3",style:{background:"var(--p-content-background)","border-bottom":"1px solid var(--p-content-border-color)"}},Ei={class:"flex items-center gap-0.5 flex-1"},Li={class:"flex items-center gap-1.5 shrink-0"},Ni={key:0,class:"activity-live"},ji={class:"flex-1 overflow-y-auto",style:{background:"color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)"}},Ii=Ee({__name:"app",setup(e){const t=Mn(),n=Ao(),o=Ka(),r=qa(),a=Fa(),s=Ja(),l=s.subscribed,i=s.muted,u=V(0),d=V(0);let c=null,p=null,m=null;async function f(){try{const{data:b}=await o.get("/api/v1/keeper/logger/stats");b.success&&b.stats?.counters&&(u.value=b.stats.counters.error||0,d.value=b.stats.counters.warn||0)}catch{}}const y=[{path:"/",name:"dashboard",label:"Home",icon:"tabler:layout-dashboard"}],g=[{path:"/settings/environment",name:"settings-environment",label:"Environment",icon:"tabler:variable"},{path:"/settings/registry",name:"settings-registry",label:"Registry",icon:"tabler:database"},{path:"/settings/hub",name:"settings-hub",label:"Wippy Hub",icon:"tabler:cloud"},{path:"/mcp",name:"mcp",label:"MCP",icon:"tabler:plug-connected"}],_=[{path:"/sessions",name:"sessions",label:"Sessions",icon:"tabler:list"},{path:"/dataflows",name:"workflow",label:"Dataflows",icon:"tabler:git-merge"},{path:"/system",name:"system",label:"System",icon:"tabler:activity"},{path:"/logs",name:"logs",label:"Logs",icon:"tabler:file-text"}],k=[],N=[{path:"/structure",name:"structure",label:"Registry",icon:"tabler:binary-tree"},{path:"/agents",name:"agents",label:"Agents",icon:"tabler:robot"},{path:"/models",name:"models",label:"Models",icon:"tabler:brain"},{path:"/tools",name:"tools",label:"Tools",icon:"tabler:tool"},{path:"/traits",name:"traits",label:"Traits",icon:"tabler:sparkles"},{path:"/endpoints",name:"endpoints",label:"Endpoints",icon:"tabler:api"},{path:"/policies",name:"policies",label:"Policies",icon:"tabler:shield-check"}],v=[{path:"/tasks",name:"tasks",label:"Pipeline",icon:"tabler:git-merge"},{path:"/changes",name:"changes",label:"Changes",icon:"tabler:git-branch"},{path:"/components",name:"components",label:"Components",icon:"tabler:puzzle"},{path:"/knowledge",name:"knowledge",label:"Knowledge",icon:"tabler:brain"},{path:"/tests",name:"tests",label:"Tests",icon:"tabler:test-pipe"}],w=V([]);async function B(){try{const{data:b}=await o.get("/api/public/pages/list");if(!b?.success||!Array.isArray(b.pages))return;w.value=b.pages.filter(h=>h.announced&&h.id.startsWith("keeper.")&&h.id!=="keeper:main").sort((h,ie)=>(h.order||9999)-(ie.order||9999)||h.title.localeCompare(ie.title)).map(h=>({path:`/plugin/${h.id}`,name:`plugin:${h.id}`,label:h.title||h.name,icon:h.icon||"tabler:puzzle",group:h.group||"develop"}))}catch{}}const H=q(()=>[..._,...w.value.filter(b=>b.group==="observe")]),ue=q(()=>[...N,...w.value.filter(b=>b.group==="structure")]),de=q(()=>[...v,...w.value.filter(b=>b.group==="develop"||!b.group)]),ce=q(()=>[...k,...w.value.filter(b=>b.group==="status")]),G=V(!1),te=V(!1),ne=V(!1),Y=V(!1),oe=V(!1),re=V(!1),he=q(()=>new Set(ce.value.map(b=>b.name))),Se=q(()=>new Set(ue.value.map(b=>b.name))),_e=q(()=>new Set(de.value.map(b=>b.name))),pe=q(()=>new Set(H.value.map(b=>b.name))),le=q(()=>new Set(g.map(b=>b.name))),R=q(()=>n.name),je=q(()=>he.value.has(String(R.value))),we=q(()=>Se.value.has(String(R.value))),ft=q(()=>_e.value.has(String(R.value))),bt=q(()=>pe.value.has(String(R.value))||R.value==="session-detail"||R.value==="dataflow-detail"),At=q(()=>le.value.has(String(R.value))||R.value==="settings"),vt=V(null);function Ie(b){t.push(b)}function Et(){G.value=!1,te.value=!1,ne.value=!1,Y.value=!1,oe.value=!1,re.value=!1}function xe(b){Ie(b),Et()}async function Lt(){try{const{data:b}=await o.get("/api/v1/user/me");b.success&&b.user&&(vt.value={email:b.user.email,full_name:b.user.full_name})}catch{}}const gt=V([]);async function Nt(){try{const{data:b}=await o.get("/api/v1/keeper/agents/list",{params:{public_only:!0}});gt.value=b.agents||[]}catch{}}function jt(b){r.startChat(b,{sidebar:!0}),re.value=!1}const $e=V(!1),Oe=V(""),ae=V([]),ze=V(!1);let He=null;const It=[{prefix:"session:",desc:"Search sessions by title or ID",icon:"tabler:list"},{prefix:"dataflow:",desc:"Search dataflows",icon:"tabler:git-merge"},{prefix:"agent:",desc:"Search agents",icon:"tabler:robot"},{prefix:"model:",desc:"Search LLM models",icon:"tabler:brain"},{prefix:"tool:",desc:"Search tools",icon:"tabler:tool"},{prefix:"endpoint:",desc:"Search HTTP endpoints",icon:"tabler:api"},{prefix:"",desc:"Search all registry entries",icon:"tabler:search"}];async function ht(){const b=Oe.value.trim();if(!b){ae.value=[];return}ze.value=!0;try{const h=b.indexOf(":"),ie=h>0?b.slice(0,h).toLowerCase():"",P=h>0?b.slice(h+1).trim():b;if(ie==="session"){const{data:Q}=await o.get("/api/v1/sessions",{params:{limit:20}}),W=(Q.sessions||[]).filter(S=>!P||S.title?.toLowerCase().includes(P.toLowerCase())||S.session_id?.includes(P)||S.current_agent?.toLowerCase().includes(P.toLowerCase()));ae.value=W.slice(0,15).map(S=>({id:S.title||S.session_id?.slice(0,12)+"...",kind:S.current_agent||"session",snippet:[S.current_model,S.status,Dn(S.last_message_date||S.start_date)].filter(Boolean).join(" · "),icon:"tabler:message",color:"var(--p-info-500)",route:"/session/"+S.session_id}))}else if(ie==="dataflow"){const{data:Q}=await o.get("/api/v1/dataflows",{params:{limit:20}}),W=(Q.dataflows||[]).filter(S=>!P||S.metadata?.title?.toLowerCase().includes(P.toLowerCase())||S.dataflow_id?.includes(P));ae.value=W.slice(0,15).map(S=>({id:S.metadata?.title||S.dataflow_id?.slice(0,12)+"...",kind:S.status||"dataflow",snippet:[S.type,Dn(S.created_at)].filter(Boolean).join(" · "),icon:"tabler:git-merge",color:S.status==="running"?"var(--p-success-500)":S.status==="failed"?"var(--p-danger-500)":"var(--p-info-500)",route:"/dataflow/"+S.dataflow_id}))}else if(ie==="agent"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"agent.gen1",limit:100}}),W=(Q.entries||[]).filter(S=>!P||S.id.toLowerCase().includes(P.toLowerCase())||S.meta?.title?.toLowerCase().includes(P.toLowerCase()));ae.value=W.slice(0,15).map(S=>({id:S.id,kind:S.kind,snippet:S.meta?.title||"",icon:"tabler:robot",color:"var(--p-warn-500)",route:"/structure?entry="+S.id}))}else if(ie==="model"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"llm.model",limit:100}}),W=(Q.entries||[]).filter(S=>!P||S.id.toLowerCase().includes(P.toLowerCase())||S.meta?.title?.toLowerCase().includes(P.toLowerCase()));ae.value=W.slice(0,15).map(S=>({id:S.id,kind:S.kind,snippet:S.meta?.title||"",icon:"tabler:brain",color:"var(--p-accent-500)",route:"/structure?entry="+S.id}))}else if(ie==="tool"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"tool",limit:100}}),W=(Q.entries||[]).filter(S=>!P||S.id.toLowerCase().includes(P.toLowerCase())||S.meta?.title?.toLowerCase().includes(P.toLowerCase()));ae.value=W.slice(0,15).map(S=>({id:S.id,kind:S.kind,snippet:S.meta?.comment||S.meta?.llm_alias||"",icon:"tabler:tool",color:"var(--p-info-500)",route:"/structure?entry="+S.id}))}else if(ie==="endpoint"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{kind:"http.endpoint",limit:200}}),W=(Q.entries||[]).filter(S=>!P||S.id.toLowerCase().includes(P.toLowerCase()));ae.value=W.slice(0,15).map(S=>({id:S.id,kind:S.kind,snippet:S.meta?.comment||"",icon:"tabler:api",color:"var(--p-info-500)",route:"/structure?entry="+S.id}))}else{const{data:Q}=await o.get("/api/v1/keeper/state/search",{params:{q:b,limit:30}});ae.value=(Q.results||[]).map(W=>({id:W.id,kind:W.kind,snippet:W.snippet,icon:fo(W.kind),color:kt(W.kind),route:"/structure?entry="+W.id}))}}catch{ae.value=[]}finally{ze.value=!1}}function Dt(){He&&clearTimeout(He),He=window.setTimeout(ht,300)}function Rt(b){Oe.value=b,ht(),window.setTimeout(()=>{const h=document.querySelector(".global-search-input");h&&(h.focus(),h.setSelectionRange(b.length,b.length))},10)}function bo(b){if($e.value=!1,Oe.value="",ae.value=[],b.route)if(b.route.includes("?")){const[h,ie]=b.route.split("?"),P=Object.fromEntries(new URLSearchParams(ie));t.push({path:h,query:P})}else t.push(b.route)}function an(b){(b.ctrlKey||b.metaKey)&&b.shiftKey&&(b.key==="F"||b.key==="f")&&(b.preventDefault(),$e.value=!0,setTimeout(()=>document.querySelector(".global-search-input")?.focus(),50)),b.key==="Escape"&&$e.value&&($e.value=!1)}function vo(){r.logout()}Re(()=>n.fullPath,()=>{try{const b={page:n.name,path:n.fullPath};n.query.entry&&(b.selected_entry=n.query.entry),n.query.ns&&(b.namespace=n.query.ns),r.setContext(b)}catch{}});function sn(b){const h=b.target;h.closest(".status-dropdown-wrap")||(G.value=!1),h.closest(".structure-dropdown-wrap")||(te.value=!1),h.closest(".develop-dropdown-wrap")||(ne.value=!1),h.closest(".observe-dropdown-wrap")||(Y.value=!1),h.closest(".settings-dropdown-wrap")||(oe.value=!1),h.closest(".agent-dropdown-wrap")||(re.value=!1)}return Vn(()=>{c=a.on("action:navigate",b=>{const h=b?.data?.path||b?.path;h&&t.push(h)}),p=a.on("keeper.logs",b=>{const h=b?.data?.counters||b?.counters;h&&(u.value=h.error||0,d.value=h.warn||0)}),m=a.on("welcome",()=>s.ensureSubscribed(o,!0)),Lt(),f(),Nt(),B(),s.ensureSubscribed(o,!0),document.addEventListener("click",sn),document.addEventListener("keydown",an)}),To(()=>{m?.(),c?.(),p?.(),document.removeEventListener("click",sn),document.removeEventListener("keydown",an)}),(b,h)=>{const ie=Ut("router-view");return O(),E("div",Ci,[M("header",Ai,[j(C(We),{variant:"text",class:"shrink-0 !gap-1.5",onClick:h[0]||(h[0]=P=>Ie("/"))},{default:Be(()=>[j(C(K),{icon:"tabler:shield-code",class:"w-4 h-4"}),h[10]||(h[10]=M("span",{class:"text-xs font-bold tracking-wider font-mono"},"KEEPER",-1))]),_:1}),M("nav",Ei,[(O(),E(et,null,tt(y,P=>j(C(We),{key:P.name,variant:"text",class:Te(["k-btn-nav relative !gap-1.5",{"k-btn-active":R.value===P.name}]),onClick:Q=>Ie(P.path)},{default:Be(()=>[j(C(K),{icon:P.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Xe(" "+X(P.label),1)]),_:2},1032,["class","onClick"])),64)),j(Ke,{icon:"tabler:eye",label:"Observe","wrap-class":"observe-dropdown-wrap",items:H.value,open:Y.value,active:bt.value,"current-name":R.value,onToggle:h[1]||(h[1]=P=>Y.value=!Y.value),onNavigate:xe},null,8,["items","open","active","current-name"]),j(Ke,{icon:"tabler:binary-tree",label:"Structure","wrap-class":"structure-dropdown-wrap",items:ue.value,open:te.value,active:we.value,"current-name":R.value,onToggle:h[2]||(h[2]=P=>te.value=!te.value),onNavigate:xe},null,8,["items","open","active","current-name"]),j(Ke,{icon:"tabler:code",label:"Develop","wrap-class":"develop-dropdown-wrap",items:de.value,open:ne.value,active:ft.value,"current-name":R.value,onToggle:h[3]||(h[3]=P=>ne.value=!ne.value),onNavigate:xe},null,8,["items","open","active","current-name"]),ce.value.length?(O(),Me(Ke,{key:0,icon:"tabler:heart-rate-monitor",label:"Status","wrap-class":"status-dropdown-wrap",items:ce.value,open:G.value,active:je.value,"current-name":R.value,onToggle:h[4]||(h[4]=P=>G.value=!G.value),onNavigate:xe},null,8,["items","open","active","current-name"])):F("",!0),j(Ke,{icon:"tabler:settings",label:"Settings","wrap-class":"settings-dropdown-wrap",items:g,open:oe.value,active:At.value,"current-name":R.value,onToggle:h[5]||(h[5]=P=>oe.value=!oe.value),onNavigate:xe},null,8,["open","active","current-name"])]),M("div",Li,[j(C(We),{variant:"text",class:Te(["k-btn-icon !rounded relative",{"k-btn-active":R.value==="activity"}]),title:C(i)?"Admin activity — muted":C(l)?"Admin activity — live":"Admin activity",onClick:h[6]||(h[6]=P=>Ie("/activity"))},{default:Be(()=>[j(C(K),{icon:C(i)?"tabler:broadcast-off":"tabler:broadcast",class:"w-4 h-4",style:zt({color:C(l)&&!C(i)?"var(--p-primary-color)":"var(--p-text-muted-color)"})},null,8,["icon","style"]),C(l)&&!C(i)?(O(),E("span",Ni)):F("",!0)]),_:1},8,["class","title"]),j(ci,{agents:gt.value,open:re.value,onToggle:h[7]||(h[7]=P=>re.value=!re.value),onStart:jt},null,8,["agents","open"]),j(fi,{user:vt.value,onLogout:vo},null,8,["user"])])]),M("main",ji,[j(ie)]),j(Ti,{open:$e.value,query:Oe.value,results:ae.value,loading:ze.value,hints:It,"onUpdate:query":h[8]||(h[8]=P=>Oe.value=P),onClose:h[9]||(h[9]=P=>$e.value=!1),onSearchInput:Dt,onSelect:bo,onApplyHint:Rt},null,8,["open","query","results","loading"])])}}}),Di=rn(Ii,[["__scopeId","data-v-ea1b5e2c"]]),Ri="modulepreload",Vi=function(e,t){return new URL(e,t).href},Rn={},A=function(t,n,o){let r=Promise.resolve();if(n&&n.length>0){let s=function(d){return Promise.all(d.map(c=>Promise.resolve(c).then(p=>({status:"fulfilled",value:p}),p=>({status:"rejected",reason:p}))))};const l=document.getElementsByTagName("link"),i=document.querySelector("meta[property=csp-nonce]"),u=i?.nonce||i?.getAttribute("nonce");r=s(n.map(d=>{if(d=Vi(d,o),d in Rn)return;Rn[d]=!0;const c=d.endsWith(".css"),p=c?'[rel="stylesheet"]':"";if(!!o)for(let y=l.length-1;y>=0;y--){const g=l[y];if(g.href===d&&(!c||g.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${d}"]${p}`))return;const f=document.createElement("link");if(f.rel=c?"stylesheet":Ri,c||(f.as="script"),f.crossOrigin="",f.href=d,u&&f.setAttribute("nonce",u),document.head.appendChild(f),c)return new Promise((y,g)=>{f.addEventListener("load",y),f.addEventListener("error",()=>g(new Error(`Unable to preload CSS for ${d}`)))})}))}function a(s){const l=new Event("vite:preloadError",{cancelable:!0});if(l.payload=s,window.dispatchEvent(l),!l.defaultPrevented)throw s}return r.then(s=>{for(const l of s||[])l.status==="rejected"&&a(l.reason);return t().catch(a)})};function Mi(e,t={}){const n=t.host??Pt,o=t.on===void 0?jo:t.on,r=Eo();t.initialPath&&r.replace(t.initialPath);const a=Lo({history:r,routes:e});Io(l=>a.resolve(l));let s;return a.afterEach(l=>{const i=s;s=void 0,n.onRouteChanged(l.fullPath,i)}),o&&o("@history",({path:l,navId:i})=>{if(!l)return;i!==void 0&&(s=i);const u=l.startsWith("/")?l:`/${l}`;a.currentRoute.value.fullPath!==u&&a.push(u)}),a}Ee({name:"WippyHostRouterLink",props:{to:{type:String,required:!0}},setup(e,{slots:t}){return()=>Ge("a",{href:e.to,onClick:n=>{n.defaultPrevented||n.button!==0||n.metaKey||n.altKey||n.ctrlKey||n.shiftKey||(n.preventDefault(),Pt.navigate(e.to))}},t.default?.())}});Ee({name:"WippyAutoRouterLink",props:{to:{type:[String,Object],required:!0},replace:{type:Boolean,default:!1},activeClass:{type:String,default:void 0},exactActiveClass:{type:String,default:void 0},ariaCurrentValue:{type:String,default:"page"},externalTarget:{type:String,default:"_blank"}},setup(e,{slots:t}){const n=Mn();return()=>{const o=n.resolve(e.to),r=Pt.classifyLink(o.href);if(r.kind==="host-nav")return Ge("a",{href:o.href,onClick:a=>{a.defaultPrevented||a.button===0&&(a.metaKey||a.altKey||a.ctrlKey||a.shiftKey||(a.preventDefault(),Pt.navigate(r.normalizedPath??r.href)))},"aria-current":e.ariaCurrentValue},t.default?.());if(r.kind==="external"){const a=e.externalTarget==="_blank";return Ge("a",{href:o.href,target:e.externalTarget||void 0,rel:a?"noopener noreferrer":void 0},t.default?.())}return r.kind==="ignore"?Ge("a",{href:o.href||"#",onClick:a=>a.preventDefault()},t.default?.()):Ge(No,{to:e.to,replace:e.replace,activeClass:e.activeClass,exactActiveClass:e.exactActiveClass,ariaCurrentValue:e.ariaCurrentValue},t.default?{default:a=>t.default?.(a)}:void 0)}}});const Bi=[{path:"/",name:"dashboard",component:()=>A(()=>import("./assets/dashboard-C2-SJOXN.js"),__vite__mapDeps([0,1,2,3,4,5,6,7,8]),import.meta.url)},{path:"/dataflows",name:"workflow",component:()=>A(()=>import("./assets/workflow-BnPrisCC.js"),__vite__mapDeps([9,3]),import.meta.url)},{path:"/sessions",name:"sessions",component:()=>A(()=>import("./assets/sessions-BrMpENKd.js"),__vite__mapDeps([10,11]),import.meta.url)},{path:"/session/:id",name:"session-detail",component:()=>A(()=>import("./assets/session-detail-BgaJxj_x.js"),__vite__mapDeps([12,1,13,14,15]),import.meta.url)},{path:"/agents",name:"agents",component:()=>A(()=>import("./assets/agents-ByacHkKz.js"),__vite__mapDeps([16,1,8,17,14,15,11]),import.meta.url)},{path:"/models",name:"models",component:()=>A(()=>import("./assets/models-BGLayZfU.js"),__vite__mapDeps([18,1,8,17,14,15,11]),import.meta.url)},{path:"/tools",name:"tools",component:()=>A(()=>import("./assets/tools-page-CAPkcnkU.js"),__vite__mapDeps([19,1,8,17,14,15,11]),import.meta.url)},{path:"/traits",name:"traits",component:()=>A(()=>import("./assets/traits-BCdYpwJm.js"),__vite__mapDeps([20,1,8,17,14,15,11]),import.meta.url)},{path:"/endpoints",name:"endpoints",component:()=>A(()=>import("./assets/endpoints-Va7stiZG.js"),__vite__mapDeps([21,1,17,14,15,11]),import.meta.url)},{path:"/policies",name:"policies",component:()=>A(()=>import("./assets/policies-C7MNLQNg.js"),__vite__mapDeps([22,1,8,17,14,15,11]),import.meta.url)},{path:"/structure",name:"structure",component:()=>A(()=>import("./assets/structure-BoeDRm0U.js"),__vite__mapDeps([23,8]),import.meta.url)},{path:"/dataflow/:id",name:"dataflow-detail",component:()=>A(()=>import("./assets/dataflow-detail-BZVhBmyi.js"),__vite__mapDeps([24,1,3,13,15]),import.meta.url)},{path:"/plugin/:id",name:"plugin",component:()=>A(()=>import("./assets/plugin-page-78CA4jh7.js"),__vite__mapDeps([25,26]),import.meta.url)},{path:"/logs",name:"logs",component:()=>A(()=>import("./assets/logger-CJ4vPYnn.js"),__vite__mapDeps([27,6,11]),import.meta.url)},{path:"/activity",name:"activity",component:()=>A(()=>import("./assets/activity-BTPuvvNP.js"),__vite__mapDeps([28,11]),import.meta.url)},{path:"/system",name:"system",component:()=>A(()=>import("./assets/system-Ba_7tip8.js"),__vite__mapDeps([29,2,11]),import.meta.url)},{path:"/tests",name:"tests",component:()=>A(()=>import("./assets/tests-C21pmcDl.js"),__vite__mapDeps([30,8]),import.meta.url)},{path:"/settings",name:"settings",component:()=>A(()=>import("./assets/settings-86u394KL.js"),__vite__mapDeps([31,11]),import.meta.url)},{path:"/settings/environment",name:"settings-environment",component:()=>A(()=>import("./assets/settings-environment-DV741d7r.js"),__vite__mapDeps([32,11]),import.meta.url)},{path:"/settings/registry",name:"settings-registry",component:()=>A(()=>import("./assets/settings-registry-CUu_UwsG.js"),__vite__mapDeps([33,11]),import.meta.url)},{path:"/settings/hub",name:"settings-hub",component:()=>A(()=>import("./assets/settings-hub-7zVX1Nd8.js"),__vite__mapDeps([34,1,35,11]),import.meta.url)},{path:"/settings/hub/:org/:name",name:"settings-hub-module",component:()=>A(()=>import("./assets/settings-hub-module-B1YBrV81.js"),__vite__mapDeps([36,1,35]),import.meta.url)},{path:"/knowledge",name:"knowledge",component:()=>A(()=>import("./assets/knowledge-B7f2toOe.js"),__vite__mapDeps([37,7,13]),import.meta.url)},{path:"/mcp",name:"mcp",component:()=>A(()=>import("./assets/mcp-TswBPJzT.js"),[],import.meta.url)},{path:"/components",name:"components",component:()=>A(()=>import("./assets/components-C4F7M12i.js"),__vite__mapDeps([38,13,15]),import.meta.url)},{path:"/tasks",name:"tasks",component:()=>A(()=>import("./assets/tasks-C61-GdIs.js"),__vite__mapDeps([39,4]),import.meta.url)},{path:"/tasks/:id",name:"task-detail",component:()=>A(()=>import("./assets/task-detail-CkwwjE7P.js"),__vite__mapDeps([40,1,4,13]),import.meta.url)},{path:"/changes",name:"changes",component:()=>A(()=>import("./assets/changes-DTloMyYz.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/changes/:id",name:"changes-detail",component:()=>A(()=>import("./assets/changes-DTloMyYz.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/audit",name:"audit",component:()=>A(()=>import("./assets/audit-CZqtKQmG.js"),[],import.meta.url)},{path:"/:pathMatch(.*)*",name:"not-found",redirect:"/"}];function Wi(e,t,n){return Mi(Bi,{initialPath:n,host:e,on:t})}async function Ui(){const e=await window.$W.config(),t=await window.$W.host(),n=await window.$W.api(),o=await window.$W.instance();n.interceptors.response.use(u=>u,u=>(u?.response?.status===401&&t.handleError("auth-expired",{url:u?.config?.url,method:u?.config?.method,message:u?.message}),Promise.reject(u)));let r=null;try{r=await window.$W.on()}catch{}const a=e.context?.route||"/",s=e.theming?.global?.icons??e.theming?.global?.iconSets?.custom;s&&go({prefix:"custom",icons:s});const l=Co(Di);l.use(ho()),l.use(Wr),l.provide(lo,t),l.provide(uo,n),l.provide(co,o),l.provide(za,e),r&&l.provide(Ha,r);const i=Wi(t,o.on,a);return l.use(i),l}async function zi(e="#app"){const t=await Ui();return t.mount(e),t}zi();export{as as $,$s as A,ks as B,Ss as C,Xr as D,ds as E,D as F,ns as G,os as H,$ as I,is as J,I as K,rs as L,or as M,Ji as N,us as O,Zi as P,nn as Q,Ea as R,Ze as S,Qo as T,Jo as U,nr as V,qn as W,es as X,rr as Y,qt as Z,rn as _,so as a,zn as a0,io as a1,Fn as a2,ss as a3,fn as a4,mn as a5,Qi as a6,Yi as a7,ls as a8,ts as a9,Xi as aa,Le as ab,pn as ac,cs as b,Ps as c,Fa as d,Cs as e,Ts as f,hs as g,Os as h,xs as i,qa as j,ms as k,ps as l,A as m,kt as n,fo as o,ys as p,fs as q,bs as r,We as s,Dn as t,Ka as u,Ja as v,vs as w,gs as x,_s as y,ws as z};
