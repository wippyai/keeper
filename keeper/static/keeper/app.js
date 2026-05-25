const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./assets/dashboard-BoC60m2r.js","./assets/index-z4psxh5h.js","./assets/pm-Dj_62FpQ.js","./assets/dataflows-Dr2Ef8bh.js","./assets/tasks-CxgCqZXy.js","./assets/changelog-kS_NZw1C.js","./assets/logger-Cq9hvQPy.js","./assets/knowledge-iW30SVUZ.js","./assets/utils-CSjTgnrH.js","./assets/workflow-BnPrisCC.js","./assets/sessions-BrMpENKd.js","./assets/PageHeader.vue_vue_type_script_setup_true_lang-x-0LZxLa.js","./assets/session-detail-bdehc96W.js","./assets/MarkdownContent-DyBNkW15.js","./assets/DetailPanel.vue_vue_type_script_setup_true_lang-B115sO7W.js","./assets/JsonBlock.vue_vue_type_script_setup_true_lang-D4lkhHol.js","./assets/agents-CXZKW6R6.js","./assets/EntryDetailPanel-BqvPycay.js","./assets/models-DagISYWm.js","./assets/tools-page-BnGcuW3d.js","./assets/traits-CqK6Tvxw.js","./assets/endpoints-BP0DLIfc.js","./assets/policies-A8uyu8Ny.js","./assets/structure-B1RAr-WV.js","./assets/dataflow-detail-BKm98Fuh.js","./assets/plugin-page-DbeqvIim.js","./assets/PluginHost.vue_vue_type_script_setup_true_lang-DnXicjf2.js","./assets/logger-CJ4vPYnn.js","./assets/system-Ba_7tip8.js","./assets/tests-C21pmcDl.js","./assets/settings-86u394KL.js","./assets/settings-environment-0WJtHASA.js","./assets/settings-registry-DF_Q3U4N.js","./assets/settings-hub-B-3IO59d.js","./assets/RequirementValueInput-CzlAplA9.js","./assets/settings-hub-module-a6OXDRnn.js","./assets/knowledge-B7f2toOe.js","./assets/components-C4F7M12i.js","./assets/tasks-C61-GdIs.js","./assets/task-detail-CQKVHbFl.js","./assets/changes-DuD77g77.js"])))=>i.map(i=>d[i]);
import{Icon as ee,addCollection as Gn}from"@iconify/vue";import{createPinia as Yn}from"pinia";import{ref as B,readonly as Qn,getCurrentInstance as Ft,onMounted as Pn,nextTick as Zn,watch as Ie,reactive as Jn,useId as Xn,mergeProps as J,openBlock as T,createElementBlock as L,createElementVNode as M,renderSlot as We,createTextVNode as Ge,toDisplayString as X,resolveComponent as Rt,resolveDirective as eo,withDirectives as to,createBlock as Re,resolveDynamicComponent as no,withCtx as Ye,createCommentVNode as te,normalizeClass as Ve,inject as Wt,defineComponent as Ae,createVNode as j,unref as D,Fragment as Qe,renderList as Ze,Teleport as oo,withModifiers as ro,withKeys as Gt,normalizeStyle as Yt,computed as H,onUnmounted as ao,h as qe,createApp as io}from"vue";import{useRouter as On,useRoute as so,createMemoryHistory as lo,createRouter as uo,RouterLink as co}from"vue-router";import{host as St,on as po,setLocalRouter as mo}from"@wippy-fe/proxy";(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))o(r);new MutationObserver(r=>{for(const i of r)if(i.type==="childList")for(const s of i.addedNodes)s.tagName==="LINK"&&s.rel==="modulepreload"&&o(s)}).observe(document,{childList:!0,subtree:!0});function n(r){const i={};return r.integrity&&(i.integrity=r.integrity),r.referrerPolicy&&(i.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?i.credentials="include":r.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function o(r){if(r.ep)return;r.ep=!0;const i=n(r);fetch(r.href,i)}})();var fo=Object.defineProperty,Qt=Object.getOwnPropertySymbols,bo=Object.prototype.hasOwnProperty,vo=Object.prototype.propertyIsEnumerable,Zt=(e,t,n)=>t in e?fo(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,go=(e,t)=>{for(var n in t||(t={}))bo.call(t,n)&&Zt(e,n,t[n]);if(Qt)for(var n of Qt(t))vo.call(t,n)&&Zt(e,n,t[n]);return e};function Le(e){return e==null||e===""||Array.isArray(e)&&e.length===0||!(e instanceof Date)&&typeof e=="object"&&Object.keys(e).length===0}function qt(e){return typeof e=="function"&&"call"in e&&"apply"in e}function N(e){return!Le(e)}function fe(e,t=!0){return e instanceof Object&&e.constructor===Object&&(t||Object.keys(e).length!==0)}function Tn(e={},t={}){let n=go({},e);return Object.keys(t).forEach(o=>{let r=o;fe(t[r])&&r in e&&fe(e[r])?n[r]=Tn(e[r],t[r]):n[r]=t[r]}),n}function ho(...e){return e.reduce((t,n,o)=>o===0?n:Tn(t,n),{})}function ie(e,...t){return qt(e)?e(...t):e}function ne(e,t=!0){return typeof e=="string"&&(t||e!=="")}function me(e){return ne(e)?e.replace(/(-|_)/g,"").toLowerCase():e}function Ht(e,t="",n={}){let o=me(t).split("."),r=o.shift();if(r){if(fe(e)){let i=Object.keys(e).find(s=>me(s)===r)||"";return Ht(ie(e[i],n),o.join("."),n)}return}return ie(e,n)}function xn(e,t=!0){return Array.isArray(e)&&(t||e.length!==0)}function yo(e){return N(e)&&!isNaN(e)}function xe(e,t){if(t){let n=t.test(e);return t.lastIndex=0,n}return!1}function _o(...e){return ho(...e)}function Ke(e){return e&&e.replace(/\/\*(?:(?!\*\/)[\s\S])*\*\/|[\r\n\t]+/g,"").replace(/ {2,}/g," ").replace(/ ([{:}]) /g,"$1").replace(/([;,]) /g,"$1").replace(/ !/g,"!").replace(/: /g,":").trim()}function So(e){return ne(e,!1)?e[0].toUpperCase()+e.slice(1):e}function Cn(e){return ne(e)?e.replace(/(_)/g,"-").replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase():e}function An(){let e=new Map;return{on(t,n){let o=e.get(t);return o?o.push(n):o=[n],e.set(t,o),this},off(t,n){let o=e.get(t);return o&&o.splice(o.indexOf(n)>>>0,1),this},emit(t,n){let o=e.get(t);o&&o.forEach(r=>{r(n)})},clear(){e.clear()}}}function Fe(...e){if(e){let t=[];for(let n=0;n<e.length;n++){let o=e[n];if(!o)continue;let r=typeof o;if(r==="string"||r==="number")t.push(o);else if(r==="object"){let i=Array.isArray(o)?[Fe(...o)]:Object.entries(o).map(([s,l])=>l?s:void 0);t=i.length?t.concat(i.filter(s=>!!s)):t}}return t.join(" ").trim()}}function ko(e,t){return e?e.classList?e.classList.contains(t):new RegExp("(^| )"+t+"( |$)","gi").test(e.className):!1}function wo(e,t){if(e&&t){let n=o=>{ko(e,o)||(e.classList?e.classList.add(o):e.className+=" "+o)};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Et(e,t){if(e&&t){let n=o=>{e.classList?e.classList.remove(o):e.className=e.className.replace(new RegExp("(^|\\b)"+o.split(" ").join("|")+"(\\b|$)","gi")," ")};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Jt(e){return e?Math.abs(e.scrollLeft):0}function $o(e,t){return e instanceof HTMLElement?e.offsetWidth:0}function Po(e){if(e){let t=e.parentNode;return t&&t instanceof ShadowRoot&&t.host&&(t=t.host),t}return null}function Oo(e){return!!(e!==null&&typeof e<"u"&&e.nodeName&&Po(e))}function dt(e){return typeof Element<"u"?e instanceof Element:e!==null&&typeof e=="object"&&e.nodeType===1&&typeof e.nodeName=="string"}function kt(e,t={}){if(dt(e)){let n=(o,r)=>{var i,s;let l=(i=e?.$attrs)!=null&&i[o]?[(s=e?.$attrs)==null?void 0:s[o]]:[];return[r].flat().reduce((a,u)=>{if(u!=null){let d=typeof u;if(d==="string"||d==="number")a.push(u);else if(d==="object"){let c=Array.isArray(u)?n(o,u):Object.entries(u).map(([p,m])=>o==="style"&&(m||m===0)?`${p.replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()}:${m}`:m?p:void 0);a=c.length?a.concat(c.filter(p=>!!p)):a}}return a},l)};Object.entries(t).forEach(([o,r])=>{if(r!=null){let i=o.match(/^on(.+)/);i?e.addEventListener(i[1].toLowerCase(),r):o==="p-bind"||o==="pBind"?kt(e,r):(r=o==="class"?[...new Set(n("class",r))].join(" ").trim():o==="style"?n("style",r).join(";").trim():r,(e.$attrs=e.$attrs||{})&&(e.$attrs[o]=r),e.setAttribute(o,r))}})}}function To(e,t={},...n){{let o=document.createElement(e);return kt(o,t),o.append(...n),o}}function xo(e,t){return dt(e)?e.matches(t)?e:e.querySelector(t):null}function Co(e,t){if(dt(e)){let n=e.getAttribute(t);return isNaN(n)?n==="true"||n==="false"?n==="true":n:+n}}function Xt(e){if(e){let t=e.offsetHeight,n=getComputedStyle(e);return t-=parseFloat(n.paddingTop)+parseFloat(n.paddingBottom)+parseFloat(n.borderTopWidth)+parseFloat(n.borderBottomWidth),t}return 0}function Ao(e){if(e){let t=e.getBoundingClientRect();return{top:t.top+(window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0),left:t.left+(window.pageXOffset||Jt(document.documentElement)||Jt(document.body)||0)}}return{top:"auto",left:"auto"}}function Lo(e,t){return e?e.offsetHeight:0}function en(e){if(e){let t=e.offsetWidth,n=getComputedStyle(e);return t-=parseFloat(n.paddingLeft)+parseFloat(n.paddingRight)+parseFloat(n.borderLeftWidth)+parseFloat(n.borderRightWidth),t}return 0}function Eo(){return!!(typeof window<"u"&&window.document&&window.document.createElement)}function jo(e,t="",n){dt(e)&&n!==null&&n!==void 0&&e.setAttribute(t,n)}var vt={};function No(e="pui_id_"){return Object.hasOwn(vt,e)||(vt[e]=0),vt[e]++,`${e}${vt[e]}`}var Io=Object.defineProperty,Do=Object.defineProperties,Ro=Object.getOwnPropertyDescriptors,wt=Object.getOwnPropertySymbols,Ln=Object.prototype.hasOwnProperty,En=Object.prototype.propertyIsEnumerable,tn=(e,t,n)=>t in e?Io(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,de=(e,t)=>{for(var n in t||(t={}))Ln.call(t,n)&&tn(e,n,t[n]);if(wt)for(var n of wt(t))En.call(t,n)&&tn(e,n,t[n]);return e},jt=(e,t)=>Do(e,Ro(t)),_e=(e,t)=>{var n={};for(var o in e)Ln.call(e,o)&&t.indexOf(o)<0&&(n[o]=e[o]);if(e!=null&&wt)for(var o of wt(e))t.indexOf(o)<0&&En.call(e,o)&&(n[o]=e[o]);return n},Vo=An(),W=Vo,Je=/{([^}]*)}/g,jn=/(\d+\s+[\+\-\*\/]\s+\d+)/g,Nn=/var\([^)]+\)/g;function nn(e){return ne(e)?e.replace(/[A-Z]/g,(t,n)=>n===0?t:"."+t.toLowerCase()).toLowerCase():e}function Mo(e){return fe(e)&&e.hasOwnProperty("$value")&&e.hasOwnProperty("$type")?e.$value:e}function Bo(e){return e.replaceAll(/ /g,"").replace(/[^\w]/g,"-")}function Vt(e="",t=""){return Bo(`${ne(e,!1)&&ne(t,!1)?`${e}-`:e}${t}`)}function In(e="",t=""){return`--${Vt(e,t)}`}function Uo(e=""){let t=(e.match(/{/g)||[]).length,n=(e.match(/}/g)||[]).length;return(t+n)%2!==0}function Dn(e,t="",n="",o=[],r){if(ne(e)){let i=e.trim();if(Uo(i))return;if(xe(i,Je)){let s=i.replaceAll(Je,l=>{let a=l.replace(/{|}/g,"").split(".").filter(u=>!o.some(d=>xe(u,d)));return`var(${In(n,Cn(a.join("-")))}${N(r)?`, ${r}`:""})`});return xe(s.replace(Nn,"0"),jn)?`calc(${s})`:s}return i}else if(yo(e))return e}function zo(e,t,n){ne(t,!1)&&e.push(`${t}:${n};`)}function Ne(e,t){return e?`${e}{${t}}`:""}function Rn(e,t){if(e.indexOf("dt(")===-1)return e;function n(s,l){let a=[],u=0,d="",c=null,p=0;for(;u<=s.length;){let m=s[u];if((m==='"'||m==="'"||m==="`")&&s[u-1]!=="\\"&&(c=c===m?null:m),!c&&(m==="("&&p++,m===")"&&p--,(m===","||u===s.length)&&p===0)){let b=d.trim();b.startsWith("dt(")?a.push(Rn(b,l)):a.push(o(b)),d="",u++;continue}m!==void 0&&(d+=m),u++}return a}function o(s){let l=s[0];if((l==='"'||l==="'"||l==="`")&&s[s.length-1]===l)return s.slice(1,-1);let a=Number(s);return isNaN(a)?s:a}let r=[],i=[];for(let s=0;s<e.length;s++)if(e[s]==="d"&&e.slice(s,s+3)==="dt(")i.push(s),s+=2;else if(e[s]===")"&&i.length>0){let l=i.pop();i.length===0&&r.push([l,s])}if(!r.length)return e;for(let s=r.length-1;s>=0;s--){let[l,a]=r[s],u=e.slice(l+3,a),d=n(u,t),c=t(...d);e=e.slice(0,l)+c+e.slice(a+1)}return e}var Ce=(...e)=>Wo(E.getTheme(),...e),Wo=(e={},t,n,o)=>{if(t){let{variable:r,options:i}=E.defaults||{},{prefix:s,transform:l}=e?.options||i||{},a=xe(t,Je)?t:`{${t}}`;return o==="value"||Le(o)&&l==="strict"?E.getTokenValue(t):Dn(a,void 0,s,[r.excludedKeyRegex],n)}return""};function gt(e,...t){if(e instanceof Array){let n=e.reduce((o,r,i)=>{var s;return o+r+((s=ie(t[i],{dt:Ce}))!=null?s:"")},"");return Rn(n,Ce)}return ie(e,{dt:Ce})}function qo(e,t={}){let n=E.defaults.variable,{prefix:o=n.prefix,selector:r=n.selector,excludedKeyRegex:i=n.excludedKeyRegex}=t,s=[],l=[],a=[{node:e,path:o}];for(;a.length;){let{node:d,path:c}=a.pop();for(let p in d){let m=d[p],b=Mo(m),_=xe(p,i)?Vt(c):Vt(c,Cn(p));if(fe(b))a.push({node:b,path:_});else{let h=In(_),S=Dn(b,_,o,[i]);zo(l,h,S);let O=_;o&&O.startsWith(o+"-")&&(O=O.slice(o.length+1)),s.push(O.replace(/-/g,"."))}}}let u=l.join("");return{value:l,tokens:s,declarations:u,css:Ne(r,u)}}var ue={regex:{rules:{class:{pattern:/^\.([a-zA-Z][\w-]*)$/,resolve(e){return{type:"class",selector:e,matched:this.pattern.test(e.trim())}}},attr:{pattern:/^\[(.*)\]$/,resolve(e){return{type:"attr",selector:`:root${e},:host${e}`,matched:this.pattern.test(e.trim())}}},media:{pattern:/^@media (.*)$/,resolve(e){return{type:"media",selector:e,matched:this.pattern.test(e.trim())}}},system:{pattern:/^system$/,resolve(e){return{type:"system",selector:"@media (prefers-color-scheme: dark)",matched:this.pattern.test(e.trim())}}},custom:{resolve(e){return{type:"custom",selector:e,matched:!0}}}},resolve(e){let t=Object.keys(this.rules).filter(n=>n!=="custom").map(n=>this.rules[n]);return[e].flat().map(n=>{var o;return(o=t.map(r=>r.resolve(n)).find(r=>r.matched))!=null?o:this.rules.custom.resolve(n)})}},_toVariables(e,t){return qo(e,{prefix:t?.prefix})},getCommon({name:e="",theme:t={},params:n,set:o,defaults:r}){var i,s,l,a,u,d,c;let{preset:p,options:m}=t,b,_,h,S,O,C,v;if(N(p)&&m.transform!=="strict"){let{primitive:k,semantic:R,extend:U}=p,K=R||{},{colorScheme:F}=K,oe=_e(K,["colorScheme"]),G=U||{},{colorScheme:Y}=G,be=_e(G,["colorScheme"]),ce=F||{},{dark:ve}=ce,Se=_e(ce,["dark"]),ge=Y||{},{dark:V}=ge,ke=_e(ge,["dark"]),le=N(k)?this._toVariables({primitive:k},m):{},se=N(oe)?this._toVariables({semantic:oe},m):{},he=N(Se)?this._toVariables({light:Se},m):{},Ee=N(ve)?this._toVariables({dark:ve},m):{},ye=N(be)?this._toVariables({semantic:be},m):{},je=N(ke)?this._toVariables({light:ke},m):{},ct=N(V)?this._toVariables({dark:V},m):{},[Oe,$t]=[(i=le.declarations)!=null?i:"",le.tokens],[pt,Pt]=[(s=se.declarations)!=null?s:"",se.tokens||[]],[Ot,we]=[(l=he.declarations)!=null?l:"",he.tokens||[]],[Te,re]=[(a=Ee.declarations)!=null?a:"",Ee.tokens||[]],[Me,Be]=[(u=ye.declarations)!=null?u:"",ye.tokens||[]],[Tt,mt]=[(d=je.declarations)!=null?d:"",je.tokens||[]],[xt,Ct]=[(c=ct.declarations)!=null?c:"",ct.tokens||[]];b=this.transformCSS(e,Oe,"light","variable",m,o,r),_=$t;let At=this.transformCSS(e,`${pt}${Ot}`,"light","variable",m,o,r),ft=this.transformCSS(e,`${Te}`,"dark","variable",m,o,r);h=`${At}${ft}`,S=[...new Set([...Pt,...we,...re])];let Lt=this.transformCSS(e,`${Me}${Tt}color-scheme:light`,"light","variable",m,o,r),bt=this.transformCSS(e,`${xt}color-scheme:dark`,"dark","variable",m,o,r);O=`${Lt}${bt}`,C=[...new Set([...Be,...mt,...Ct])],v=ie(p.css,{dt:Ce})}return{primitive:{css:b,tokens:_},semantic:{css:h,tokens:S},global:{css:O,tokens:C},style:v}},getPreset({name:e="",preset:t={},options:n,params:o,set:r,defaults:i,selector:s}){var l,a,u;let d,c,p;if(N(t)&&n.transform!=="strict"){let m=e.replace("-directive",""),b=t,{colorScheme:_,extend:h,css:S}=b,O=_e(b,["colorScheme","extend","css"]),C=h||{},{colorScheme:v}=C,k=_e(C,["colorScheme"]),R=_||{},{dark:U}=R,K=_e(R,["dark"]),F=v||{},{dark:oe}=F,G=_e(F,["dark"]),Y=N(O)?this._toVariables({[m]:de(de({},O),k)},n):{},be=N(K)?this._toVariables({[m]:de(de({},K),G)},n):{},ce=N(U)?this._toVariables({[m]:de(de({},U),oe)},n):{},[ve,Se]=[(l=Y.declarations)!=null?l:"",Y.tokens||[]],[ge,V]=[(a=be.declarations)!=null?a:"",be.tokens||[]],[ke,le]=[(u=ce.declarations)!=null?u:"",ce.tokens||[]],se=this.transformCSS(m,`${ve}${ge}`,"light","variable",n,r,i,s),he=this.transformCSS(m,ke,"dark","variable",n,r,i,s);d=`${se}${he}`,c=[...new Set([...Se,...V,...le])],p=ie(S,{dt:Ce})}return{css:d,tokens:c,style:p}},getPresetC({name:e="",theme:t={},params:n,set:o,defaults:r}){var i;let{preset:s,options:l}=t,a=(i=s?.components)==null?void 0:i[e];return this.getPreset({name:e,preset:a,options:l,params:n,set:o,defaults:r})},getPresetD({name:e="",theme:t={},params:n,set:o,defaults:r}){var i,s;let l=e.replace("-directive",""),{preset:a,options:u}=t,d=((i=a?.components)==null?void 0:i[l])||((s=a?.directives)==null?void 0:s[l]);return this.getPreset({name:l,preset:d,options:u,params:n,set:o,defaults:r})},applyDarkColorScheme(e){return!(e.darkModeSelector==="none"||e.darkModeSelector===!1)},getColorSchemeOption(e,t){var n;return this.applyDarkColorScheme(e)?this.regex.resolve(e.darkModeSelector===!0?t.options.darkModeSelector:(n=e.darkModeSelector)!=null?n:t.options.darkModeSelector):[]},getLayerOrder(e,t={},n,o){let{cssLayer:r}=t;return r?`@layer ${ie(r.order||r.name||"primeui",n)}`:""},getCommonStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:i}){let s=this.getCommon({name:e,theme:t,params:n,set:r,defaults:i}),l=Object.entries(o).reduce((a,[u,d])=>a.push(`${u}="${d}"`)&&a,[]).join(" ");return Object.entries(s||{}).reduce((a,[u,d])=>{if(fe(d)&&Object.hasOwn(d,"css")){let c=Ke(d.css),p=`${u}-variables`;a.push(`<style type="text/css" data-primevue-style-id="${p}" ${l}>${c}</style>`)}return a},[]).join("")},getStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:i}){var s;let l={name:e,theme:t,params:n,set:r,defaults:i},a=(s=e.includes("-directive")?this.getPresetD(l):this.getPresetC(l))==null?void 0:s.css,u=Object.entries(o).reduce((d,[c,p])=>d.push(`${c}="${p}"`)&&d,[]).join(" ");return a?`<style type="text/css" data-primevue-style-id="${e}-variables" ${u}>${Ke(a)}</style>`:""},createTokens(e={},t,n="",o="",r={}){let i=function(l,a={},u=[]){if(u.includes(this.path))return console.warn(`Circular reference detected at ${this.path}`),{colorScheme:l,path:this.path,paths:a,value:void 0};u.push(this.path),a.name=this.path,a.binding||(a.binding={});let d=this.value;if(typeof this.value=="string"&&Je.test(this.value)){let c=this.value.trim().replace(Je,p=>{var m;let b=p.slice(1,-1),_=this.tokens[b];if(!_)return console.warn(`Token not found for path: ${b}`),"__UNRESOLVED__";let h=_.computed(l,a,u);return Array.isArray(h)&&h.length===2?`light-dark(${h[0].value},${h[1].value})`:(m=h?.value)!=null?m:"__UNRESOLVED__"});d=jn.test(c.replace(Nn,"0"))?`calc(${c})`:c}return Le(a.binding)&&delete a.binding,u.pop(),{colorScheme:l,path:this.path,paths:a,value:d.includes("__UNRESOLVED__")?void 0:d}},s=(l,a,u)=>{Object.entries(l).forEach(([d,c])=>{let p=xe(d,t.variable.excludedKeyRegex)?a:a?`${a}.${nn(d)}`:nn(d),m=u?`${u}.${d}`:d;fe(c)?s(c,p,m):(r[p]||(r[p]={paths:[],computed:(b,_={},h=[])=>{if(r[p].paths.length===1)return r[p].paths[0].computed(r[p].paths[0].scheme,_.binding,h);if(b&&b!=="none")for(let S=0;S<r[p].paths.length;S++){let O=r[p].paths[S];if(O.scheme===b)return O.computed(b,_.binding,h)}return r[p].paths.map(S=>S.computed(S.scheme,_[S.scheme],h))}}),r[p].paths.push({path:m,value:c,scheme:m.includes("colorScheme.light")?"light":m.includes("colorScheme.dark")?"dark":"none",computed:i,tokens:r}))})};return s(e,n,o),r},getTokenValue(e,t,n){var o;let r=(l=>l.split(".").filter(a=>!xe(a.toLowerCase(),n.variable.excludedKeyRegex)).join("."))(t),i=t.includes("colorScheme.light")?"light":t.includes("colorScheme.dark")?"dark":void 0,s=[(o=e[r])==null?void 0:o.computed(i)].flat().filter(l=>l);return s.length===1?s[0].value:s.reduce((l={},a)=>{let u=a,{colorScheme:d}=u,c=_e(u,["colorScheme"]);return l[d]=c,l},void 0)},getSelectorRule(e,t,n,o){return n==="class"||n==="attr"?Ne(N(t)?`${e}${t},${e} ${t}`:e,o):Ne(e,Ne(t??":root,:host",o))},transformCSS(e,t,n,o,r={},i,s,l){if(N(t)){let{cssLayer:a}=r;if(o!=="style"){let u=this.getColorSchemeOption(r,s);t=n==="dark"?u.reduce((d,{type:c,selector:p})=>(N(p)&&(d+=p.includes("[CSS]")?p.replace("[CSS]",t):this.getSelectorRule(p,l,c,t)),d),""):Ne(l??":root,:host",t)}if(a){let u={name:"primeui"};fe(a)&&(u.name=ie(a.name,{name:e,type:o})),N(u.name)&&(t=Ne(`@layer ${u.name}`,t),i?.layerNames(u.name))}return t}return""}},E={defaults:{variable:{prefix:"p",selector:":root,:host",excludedKeyRegex:/^(primitive|semantic|components|directives|variables|colorscheme|light|dark|common|root|states|extend|css)$/gi},options:{prefix:"p",darkModeSelector:"system",cssLayer:!1}},_theme:void 0,_layerNames:new Set,_loadedStyleNames:new Set,_loadingStyles:new Set,_tokens:{},update(e={}){let{theme:t}=e;t&&(this._theme=jt(de({},t),{options:de(de({},this.defaults.options),t.options)}),this._tokens=ue.createTokens(this.preset,this.defaults),this.clearLoadedStyleNames())},get theme(){return this._theme},get preset(){var e;return((e=this.theme)==null?void 0:e.preset)||{}},get options(){var e;return((e=this.theme)==null?void 0:e.options)||{}},get tokens(){return this._tokens},getTheme(){return this.theme},setTheme(e){this.update({theme:e}),W.emit("theme:change",e)},getPreset(){return this.preset},setPreset(e){this._theme=jt(de({},this.theme),{preset:e}),this._tokens=ue.createTokens(e,this.defaults),this.clearLoadedStyleNames(),W.emit("preset:change",e),W.emit("theme:change",this.theme)},getOptions(){return this.options},setOptions(e){this._theme=jt(de({},this.theme),{options:e}),this.clearLoadedStyleNames(),W.emit("options:change",e),W.emit("theme:change",this.theme)},getLayerNames(){return[...this._layerNames]},setLayerNames(e){this._layerNames.add(e)},getLoadedStyleNames(){return this._loadedStyleNames},isStyleNameLoaded(e){return this._loadedStyleNames.has(e)},setLoadedStyleName(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames(){this._loadedStyleNames.clear()},getTokenValue(e){return ue.getTokenValue(this.tokens,e,this.defaults)},getCommon(e="",t){return ue.getCommon({name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getComponent(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return ue.getPresetC(n)},getDirective(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return ue.getPresetD(n)},getCustomPreset(e="",t,n,o){let r={name:e,preset:t,options:this.options,selector:n,params:o,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return ue.getPreset(r)},getLayerOrderCSS(e=""){return ue.getLayerOrder(e,this.options,{names:this.getLayerNames()},this.defaults)},transformCSS(e="",t,n="style",o){return ue.transformCSS(e,t,o,n,this.options,{layerNames:this.setLayerNames.bind(this)},this.defaults)},getCommonStyleSheet(e="",t,n={}){return ue.getCommonStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getStyleSheet(e,t,n={}){return ue.getStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},onStyleMounted(e){this._loadingStyles.add(e)},onStyleUpdated(e){this._loadingStyles.add(e)},onStyleLoaded(e,{name:t}){this._loadingStyles.size&&(this._loadingStyles.delete(t),W.emit(`theme:${t}:load`,e),!this._loadingStyles.size&&W.emit("theme:load"))}},q={STARTS_WITH:"startsWith",CONTAINS:"contains",NOT_CONTAINS:"notContains",ENDS_WITH:"endsWith",EQUALS:"equals",NOT_EQUALS:"notEquals",LESS_THAN:"lt",LESS_THAN_OR_EQUAL_TO:"lte",GREATER_THAN:"gt",GREATER_THAN_OR_EQUAL_TO:"gte",DATE_IS:"dateIs",DATE_IS_NOT:"dateIsNot",DATE_BEFORE:"dateBefore",DATE_AFTER:"dateAfter"},Ho=`
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
`;function Xe(e){"@babel/helpers - typeof";return Xe=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},Xe(e)}function on(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function rn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?on(Object(n),!0).forEach(function(o){Ko(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):on(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ko(e,t,n){return(t=Fo(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Fo(e){var t=Go(e,"string");return Xe(t)=="symbol"?t:t+""}function Go(e,t){if(Xe(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(Xe(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function Yo(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0;Ft()&&Ft().components?Pn(e):t?e():Zn(e)}var Qo=0;function Zo(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},n=B(!1),o=B(e),r=B(null),i=Eo()?window.document:void 0,s=t.document,l=s===void 0?i:s,a=t.immediate,u=a===void 0?!0:a,d=t.manual,c=d===void 0?!1:d,p=t.name,m=p===void 0?"style_".concat(++Qo):p,b=t.id,_=b===void 0?void 0:b,h=t.media,S=h===void 0?void 0:h,O=t.nonce,C=O===void 0?void 0:O,v=t.first,k=v===void 0?!1:v,R=t.onMounted,U=R===void 0?void 0:R,K=t.onUpdated,F=K===void 0?void 0:K,oe=t.onLoad,G=oe===void 0?void 0:oe,Y=t.props,be=Y===void 0?{}:Y,ce=function(){},ve=function(V){var ke=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(l){var le=rn(rn({},be),ke),se=le.name||m,he=le.id||_,Ee=le.nonce||C;r.value=l.querySelector('style[data-primevue-style-id="'.concat(se,'"]'))||l.getElementById(he)||l.createElement("style"),r.value.isConnected||(o.value=V||e,kt(r.value,{type:"text/css",id:he,media:S,nonce:Ee}),k?l.head.prepend(r.value):l.head.appendChild(r.value),jo(r.value,"data-primevue-style-id",se),kt(r.value,le),r.value.onload=function(ye){return G?.(ye,{name:se})},U?.(se)),!n.value&&(ce=Ie(o,function(ye){r.value.textContent=ye,F?.(se)},{immediate:!0}),n.value=!0)}},Se=function(){!l||!n.value||(ce(),Oo(r.value)&&l.head.removeChild(r.value),n.value=!1,r.value=null)};return u&&!c&&Yo(ve),{id:_,name:m,el:r,css:o,unload:Se,load:ve,isLoaded:Qn(n)}}function et(e){"@babel/helpers - typeof";return et=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},et(e)}var an,sn,ln,un;function dn(e,t){return tr(e)||er(e,t)||Xo(e,t)||Jo()}function Jo(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Xo(e,t){if(e){if(typeof e=="string")return cn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?cn(e,t):void 0}}function cn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function er(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t!==0)for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function tr(e){if(Array.isArray(e))return e}function pn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function Nt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?pn(Object(n),!0).forEach(function(o){nr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):pn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function nr(e,t,n){return(t=or(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function or(e){var t=rr(e,"string");return et(t)=="symbol"?t:t+""}function rr(e,t){if(et(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(et(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function ht(e,t){return t||(t=e.slice(0)),Object.freeze(Object.defineProperties(e,{raw:{value:Object.freeze(t)}}))}var ar=function(t){var n=t.dt;return`
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
`)},ir={},sr={},I={name:"base",css:ar,style:Ho,classes:ir,inlineStyles:sr,load:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:function(i){return i},r=o(gt(an||(an=ht(["",""])),t));return N(r)?Zo(Ke(r),Nt({name:this.name},n)):{}},loadCSS:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};return this.load(this.css,t)},loadStyle:function(){var t=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"";return this.load(this.style,n,function(){var r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"";return E.transformCSS(n.name||t.name,"".concat(r).concat(gt(sn||(sn=ht(["",""])),o)))})},getCommonTheme:function(t){return E.getCommon(this.name,t)},getComponentTheme:function(t){return E.getComponent(this.name,t)},getDirectiveTheme:function(t){return E.getDirective(this.name,t)},getPresetTheme:function(t,n,o){return E.getCustomPreset(this.name,t,n,o)},getLayerOrderThemeCSS:function(){return E.getLayerOrderCSS(this.name)},getStyleSheet:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(this.css){var o=ie(this.css,{dt:Ce})||"",r=Ke(gt(ln||(ln=ht(["","",""])),o,t)),i=Object.entries(n).reduce(function(s,l){var a=dn(l,2),u=a[0],d=a[1];return s.push("".concat(u,'="').concat(d,'"'))&&s},[]).join(" ");return N(r)?'<style type="text/css" data-primevue-style-id="'.concat(this.name,'" ').concat(i,">").concat(r,"</style>"):""}return""},getCommonThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return E.getCommonStyleSheet(this.name,t,n)},getThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=[E.getStyleSheet(this.name,t,n)];if(this.style){var r=this.name==="base"?"global-style":"".concat(this.name,"-style"),i=gt(un||(un=ht(["",""])),ie(this.style,{dt:Ce})),s=Ke(E.transformCSS(r,i)),l=Object.entries(n).reduce(function(a,u){var d=dn(u,2),c=d[0],p=d[1];return a.push("".concat(c,'="').concat(p,'"'))&&a},[]).join(" ");N(s)&&o.push('<style type="text/css" data-primevue-style-id="'.concat(r,'" ').concat(l,">").concat(s,"</style>"))}return o.join("")},extend:function(t){return Nt(Nt({},this),{},{css:void 0,style:void 0},t)}},Pe=An();function tt(e){"@babel/helpers - typeof";return tt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},tt(e)}function mn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function yt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?mn(Object(n),!0).forEach(function(o){lr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):mn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function lr(e,t,n){return(t=ur(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function ur(e){var t=dr(e,"string");return tt(t)=="symbol"?t:t+""}function dr(e,t){if(tt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(tt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var cr={ripple:!1,inputStyle:null,inputVariant:null,locale:{startsWith:"Starts with",contains:"Contains",notContains:"Not contains",endsWith:"Ends with",equals:"Equals",notEquals:"Not equals",noFilter:"No Filter",lt:"Less than",lte:"Less than or equal to",gt:"Greater than",gte:"Greater than or equal to",dateIs:"Date is",dateIsNot:"Date is not",dateBefore:"Date is before",dateAfter:"Date is after",clear:"Clear",apply:"Apply",matchAll:"Match All",matchAny:"Match Any",addRule:"Add Rule",removeRule:"Remove Rule",accept:"Yes",reject:"No",choose:"Choose",upload:"Upload",cancel:"Cancel",completed:"Completed",pending:"Pending",fileSizeTypes:["B","KB","MB","GB","TB","PB","EB","ZB","YB"],dayNames:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],dayNamesShort:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],dayNamesMin:["Su","Mo","Tu","We","Th","Fr","Sa"],monthNames:["January","February","March","April","May","June","July","August","September","October","November","December"],monthNamesShort:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],chooseYear:"Choose Year",chooseMonth:"Choose Month",chooseDate:"Choose Date",prevDecade:"Previous Decade",nextDecade:"Next Decade",prevYear:"Previous Year",nextYear:"Next Year",prevMonth:"Previous Month",nextMonth:"Next Month",prevHour:"Previous Hour",nextHour:"Next Hour",prevMinute:"Previous Minute",nextMinute:"Next Minute",prevSecond:"Previous Second",nextSecond:"Next Second",am:"am",pm:"pm",today:"Today",weekHeader:"Wk",firstDayOfWeek:0,showMonthAfterYear:!1,dateFormat:"mm/dd/yy",weak:"Weak",medium:"Medium",strong:"Strong",passwordPrompt:"Enter a password",emptyFilterMessage:"No results found",searchMessage:"{0} results are available",selectionMessage:"{0} items selected",emptySelectionMessage:"No selected item",emptySearchMessage:"No results found",fileChosenMessage:"{0} files",noFileChosenMessage:"No file chosen",emptyMessage:"No available options",aria:{trueLabel:"True",falseLabel:"False",nullLabel:"Not Selected",star:"1 star",stars:"{star} stars",selectAll:"All items selected",unselectAll:"All items unselected",close:"Close",previous:"Previous",next:"Next",navigation:"Navigation",scrollTop:"Scroll Top",moveTop:"Move Top",moveUp:"Move Up",moveDown:"Move Down",moveBottom:"Move Bottom",moveToTarget:"Move to Target",moveToSource:"Move to Source",moveAllToTarget:"Move All to Target",moveAllToSource:"Move All to Source",pageLabel:"Page {page}",firstPageLabel:"First Page",lastPageLabel:"Last Page",nextPageLabel:"Next Page",prevPageLabel:"Previous Page",rowsPerPageLabel:"Rows per page",jumpToPageDropdownLabel:"Jump to Page Dropdown",jumpToPageInputLabel:"Jump to Page Input",selectRow:"Row Selected",unselectRow:"Row Unselected",expandRow:"Row Expanded",collapseRow:"Row Collapsed",showFilterMenu:"Show Filter Menu",hideFilterMenu:"Hide Filter Menu",filterOperator:"Filter Operator",filterConstraint:"Filter Constraint",editRow:"Row Edit",saveEdit:"Save Edit",cancelEdit:"Cancel Edit",listView:"List View",gridView:"Grid View",slide:"Slide",slideNumber:"{slideNumber}",zoomImage:"Zoom Image",zoomIn:"Zoom In",zoomOut:"Zoom Out",rotateRight:"Rotate Right",rotateLeft:"Rotate Left",listLabel:"Option List"}},filterMatchModeOptions:{text:[q.STARTS_WITH,q.CONTAINS,q.NOT_CONTAINS,q.ENDS_WITH,q.EQUALS,q.NOT_EQUALS],numeric:[q.EQUALS,q.NOT_EQUALS,q.LESS_THAN,q.LESS_THAN_OR_EQUAL_TO,q.GREATER_THAN,q.GREATER_THAN_OR_EQUAL_TO],date:[q.DATE_IS,q.DATE_IS_NOT,q.DATE_BEFORE,q.DATE_AFTER]},zIndex:{modal:1100,overlay:1e3,menu:1e3,tooltip:1100},theme:void 0,unstyled:!1,pt:void 0,ptOptions:{mergeSections:!0,mergeProps:!1},csp:{nonce:void 0}},pr=Symbol();function mr(e,t){var n={config:Jn(t)};return e.config.globalProperties.$primevue=n,e.provide(pr,n),fr(),br(e,n),n}var De=[];function fr(){W.clear(),De.forEach(function(e){return e?.()}),De=[]}function br(e,t){var n=B(!1),o=function(){var u;if(((u=t.config)===null||u===void 0?void 0:u.theme)!=="none"&&!E.isStyleNameLoaded("common")){var d,c,p=((d=I.getCommonTheme)===null||d===void 0?void 0:d.call(I))||{},m=p.primitive,b=p.semantic,_=p.global,h=p.style,S={nonce:(c=t.config)===null||c===void 0||(c=c.csp)===null||c===void 0?void 0:c.nonce};I.load(m?.css,yt({name:"primitive-variables"},S)),I.load(b?.css,yt({name:"semantic-variables"},S)),I.load(_?.css,yt({name:"global-variables"},S)),I.loadStyle(yt({name:"global-style"},S),h),E.setLoadedStyleName("common")}};W.on("theme:change",function(a){n.value||(e.config.globalProperties.$primevue.config.theme=a,n.value=!0)});var r=Ie(t.config,function(a,u){Pe.emit("config:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0}),i=Ie(function(){return t.config.ripple},function(a,u){Pe.emit("config:ripple:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0}),s=Ie(function(){return t.config.theme},function(a,u){n.value||E.setTheme(a),t.config.unstyled||o(),n.value=!1,Pe.emit("config:theme:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!1}),l=Ie(function(){return t.config.unstyled},function(a,u){!a&&t.config.theme&&o(),Pe.emit("config:unstyled:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0});De.push(r),De.push(i),De.push(s),De.push(l)}var vr={install:function(t,n){var o=_o(cr,n);mr(t,o)}};const gr={install:e=>e.use(vr,{theme:"none"})};var $e={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(t){return this._loadedStyleNames.has(t)},setLoadedStyleName:function(t){this._loadedStyleNames.add(t)},deleteLoadedStyleName:function(t){this._loadedStyleNames.delete(t)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function hr(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",t=Xn();return"".concat(e).concat(t.replace("v-","").replaceAll("-","_"))}var fn=I.extend({name:"common"});function nt(e){"@babel/helpers - typeof";return nt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},nt(e)}function yr(e){return Bn(e)||_r(e)||Mn(e)||Vn()}function _r(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function Ue(e,t){return Bn(e)||Sr(e,t)||Mn(e,t)||Vn()}function Vn(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Mn(e,t){if(e){if(typeof e=="string")return Mt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Mt(e,t):void 0}}function Mt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Sr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t===0){if(Object(n)!==n)return;a=!1}else for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function Bn(e){if(Array.isArray(e))return e}function bn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function P(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?bn(Object(n),!0).forEach(function(o){He(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):bn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function He(e,t,n){return(t=kr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function kr(e){var t=wr(e,"string");return nt(t)=="symbol"?t:t+""}function wr(e,t){if(nt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(nt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Kt={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(t){W.off("theme:change",this._loadCoreStyles),t||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(t,n){var o=this;W.off("theme:change",this._themeScopedListener),t?(this._loadScopedThemeStyles(t),this._themeScopedListener=function(){return o._loadScopedThemeStyles(t)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var t,n,o,r,i,s,l,a,u,d,c,p=(t=this.pt)===null||t===void 0?void 0:t._usept,m=p?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,b=p?(o=this.pt)===null||o===void 0||(o=o.value)===null||o===void 0?void 0:o[this.$.type.name]:this.pt;(r=b||m)===null||r===void 0||(r=r.hooks)===null||r===void 0||(i=r.onBeforeCreate)===null||i===void 0||i.call(r);var _=(s=this.$primevueConfig)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s._usept,h=_?(l=this.$primevue)===null||l===void 0||(l=l.config)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l.originalValue:void 0,S=_?(a=this.$primevue)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.pt)===null||a===void 0?void 0:a.value:(u=this.$primevue)===null||u===void 0||(u=u.config)===null||u===void 0?void 0:u.pt;(d=S||h)===null||d===void 0||(d=d[this.$.type.name])===null||d===void 0||(d=d.hooks)===null||d===void 0||(c=d.onBeforeCreate)===null||c===void 0||c.call(d),this.$attrSelector=hr(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var t;this.rootEl=xo(dt(this.$el)?this.$el:(t=this.$el)===null||t===void 0?void 0:t.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=P({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(t){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(t)),o=this._useDefaultPT(this._getOptionValue,"hooks.".concat(t));n?.(),o?.()}},_mergeProps:function(t){for(var n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return qt(t)?t.apply(void 0,o):J.apply(void 0,o)},_load:function(){$e.isStyleNameLoaded("base")||(I.loadCSS(this.$styleOptions),this._loadGlobalStyles(),$e.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var t,n;!$e.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(fn.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),$e.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var t=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);N(t)&&I.load(t,P({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var t,n;if(!(this.isUnstyled||this.$theme==="none")){if(!E.isStyleNameLoaded("common")){var o,r,i=((o=this.$style)===null||o===void 0||(r=o.getCommonTheme)===null||r===void 0?void 0:r.call(o))||{},s=i.primitive,l=i.semantic,a=i.global,u=i.style;I.load(s?.css,P({name:"primitive-variables"},this.$styleOptions)),I.load(l?.css,P({name:"semantic-variables"},this.$styleOptions)),I.load(a?.css,P({name:"global-variables"},this.$styleOptions)),I.loadStyle(P({name:"global-style"},this.$styleOptions),u),E.setLoadedStyleName("common")}if(!E.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var d,c,p,m,b=((d=this.$style)===null||d===void 0||(c=d.getComponentTheme)===null||c===void 0?void 0:c.call(d))||{},_=b.css,h=b.style;(p=this.$style)===null||p===void 0||p.load(_,P({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(m=this.$style)===null||m===void 0||m.loadStyle(P({name:"".concat(this.$style.name,"-style")},this.$styleOptions),h),E.setLoadedStyleName(this.$style.name)}if(!E.isStyleNameLoaded("layer-order")){var S,O,C=(S=this.$style)===null||S===void 0||(O=S.getLayerOrderThemeCSS)===null||O===void 0?void 0:O.call(S);I.load(C,P({name:"layer-order",first:!0},this.$styleOptions)),E.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(t){var n,o,r,i=((n=this.$style)===null||n===void 0||(o=n.getPresetTheme)===null||o===void 0?void 0:o.call(n,t,"[".concat(this.$attrSelector,"]")))||{},s=i.css,l=(r=this.$style)===null||r===void 0?void 0:r.load(s,P({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=l.el},_unloadScopedThemeStyles:function(){var t;(t=this.scopedStyleEl)===null||t===void 0||(t=t.value)===null||t===void 0||t.remove()},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};$e.clearLoadedStyleNames(),W.on("theme:change",t)},_removeThemeListeners:function(){W.off("theme:change",this._loadCoreStyles),W.off("theme:change",this._load),W.off("theme:change",this._themeScopedListener)},_getHostInstance:function(t){return t?this.$options.hostName?t.$.type.name===this.$options.hostName?t:this._getHostInstance(t.$parentInstance):t.$parentInstance:void 0},_getPropValue:function(t){var n;return this[t]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[t])},_getOptionValue:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return Ht(t,n,o)},_getPTValue:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},i=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,s=/./g.test(o)&&!!r[o.split(".")[0]],l=this._getPropValue("ptOptions")||((t=this.$primevueConfig)===null||t===void 0?void 0:t.ptOptions)||{},a=l.mergeSections,u=a===void 0?!0:a,d=l.mergeProps,c=d===void 0?!1:d,p=i?s?this._useGlobalPT(this._getPTClassValue,o,r):this._useDefaultPT(this._getPTClassValue,o,r):void 0,m=s?void 0:this._getPTSelf(n,this._getPTClassValue,o,P(P({},r),{},{global:p||{}})),b=this._getPTDatasets(o);return u||!u&&m?c?this._mergeProps(c,p,m,b):P(P(P({},p),m),b):P(P({},m),b)},_getPTSelf:function(){for(var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return J(this._usePT.apply(this,[this._getPT(t,this.$name)].concat(o)),this._usePT.apply(this,[this.$_attrsPT].concat(o)))},_getPTDatasets:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r="data-pc-",i=o==="root"&&N((t=this.pt)===null||t===void 0?void 0:t["data-pc-section"]);return o!=="transition"&&P(P({},o==="root"&&P(P(He({},"".concat(r,"name"),me(i?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),i&&He({},"".concat(r,"extend"),me(this.$.type.name))),{},He({},"".concat(this.$attrSelector),""))),{},He({},"".concat(r,"section"),me(o)))},_getPTClassValue:function(){var t=this._getOptionValue.apply(this,arguments);return ne(t)||xn(t)?{class:t}:t},_getPT:function(t){var n=this,o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,i=function(l){var a,u=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,d=r?r(l):l,c=me(o),p=me(n.$name);return(a=u?c!==p?d?.[c]:void 0:d?.[c])!==null&&a!==void 0?a:d};return t!=null&&t.hasOwnProperty("_usept")?{_usept:t._usept,originalValue:i(t.originalValue),value:i(t.value)}:i(t,!0)},_usePT:function(t,n,o,r){var i=function(_){return n(_,o,r)};if(t!=null&&t.hasOwnProperty("_usept")){var s,l=t._usept||((s=this.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},a=l.mergeSections,u=a===void 0?!0:a,d=l.mergeProps,c=d===void 0?!1:d,p=i(t.originalValue),m=i(t.value);return p===void 0&&m===void 0?void 0:ne(m)?m:ne(p)?p:u||!u&&m?c?this._mergeProps(c,p,m):P(P({},p),m):m}return i(t)},_useGlobalPT:function(t,n,o){return this._usePT(this.globalPT,t,n,o)},_useDefaultPT:function(t,n,o){return this._usePT(this.defaultPT,t,n,o)},ptm:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,t,P(P({},this.$params),n))},ptmi:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=J(this.$_attrsWithoutPT,this.ptm(n,o));return r?.hasOwnProperty("id")&&((t=r.id)!==null&&t!==void 0||(r.id=this.$id)),r},ptmo:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(t,n,P({instance:this},o),!1)},cx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,t,P(P({},this.$params),n))},sx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var r=this._getOptionValue(this.$style.inlineStyles,t,P(P({},this.$params),o)),i=this._getOptionValue(fn.inlineStyles,t,P(P({},this.$params),o));return[i,r]}}},computed:{globalPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return ie(o,{instance:n})})},defaultPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return n._getOptionValue(o,n.$name,P({},n.$params))||ie(o,P({},n.$params))})},isUnstyled:function(){var t;return this.unstyled!==void 0?this.unstyled:(t=this.$primevueConfig)===null||t===void 0?void 0:t.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var t,n=Object.keys(((t=this.$.vnode)===null||t===void 0?void 0:t.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(o){var r=Ue(o,1),i=r[0];return n?.includes(i)}))},$theme:function(){var t;return(t=this.$primevueConfig)===null||t===void 0?void 0:t.theme},$style:function(){return P(P({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var t;return{nonce:(t=this.$primevueConfig)===null||t===void 0||(t=t.csp)===null||t===void 0?void 0:t.nonce}},$primevueConfig:function(){var t;return(t=this.$primevue)===null||t===void 0?void 0:t.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var t=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:t,props:t?.$props,state:t?.$data,attrs:t?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=Ue(t,1),o=n[0];return o?.startsWith("pt:")}).reduce(function(t,n){var o=Ue(n,2),r=o[0],i=o[1],s=r.split(":"),l=yr(s),a=Mt(l).slice(1);return a?.reduce(function(u,d,c,p){return!u[d]&&(u[d]=c===p.length-1?i:{}),u[d]},t),t},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=Ue(t,1),o=n[0];return!(o!=null&&o.startsWith("pt:"))}).reduce(function(t,n){var o=Ue(n,2),r=o[0],i=o[1];return t[r]=i,t},{})}}},$r=`
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
`,Pr=I.extend({name:"baseicon",css:$r});function ot(e){"@babel/helpers - typeof";return ot=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ot(e)}function vn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function gn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?vn(Object(n),!0).forEach(function(o){Or(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):vn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Or(e,t,n){return(t=Tr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Tr(e){var t=xr(e,"string");return ot(t)=="symbol"?t:t+""}function xr(e,t){if(ot(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ot(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Cr={name:"BaseIcon",extends:Kt,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:Pr,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var t=Le(this.label);return gn(gn({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:t?void 0:"img","aria-label":t?void 0:this.label,"aria-hidden":t})}}},Un={name:"SpinnerIcon",extends:Cr};function Ar(e){return Nr(e)||jr(e)||Er(e)||Lr()}function Lr(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Er(e,t){if(e){if(typeof e=="string")return Bt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Bt(e,t):void 0}}function jr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function Nr(e){if(Array.isArray(e))return Bt(e)}function Bt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Ir(e,t,n,o,r,i){return T(),L("svg",J({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},e.pti()),Ar(t[0]||(t[0]=[M("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}Un.render=Ir;var Dr=`
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
`,Rr={root:function(t){var n=t.props,o=t.instance;return["p-badge p-component",{"p-badge-circle":N(n.value)&&String(n.value).length===1,"p-badge-dot":Le(n.value)&&!o.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},Vr=I.extend({name:"badge",style:Dr,classes:Rr}),Mr={name:"BaseBadge",extends:Kt,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:Vr,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function rt(e){"@babel/helpers - typeof";return rt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},rt(e)}function hn(e,t,n){return(t=Br(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Br(e){var t=Ur(e,"string");return rt(t)=="symbol"?t:t+""}function Ur(e,t){if(rt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(rt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var zn={name:"Badge",extends:Mr,inheritAttrs:!1,computed:{dataP:function(){return Fe(hn(hn({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},zr=["data-p"];function Wr(e,t,n,o,r,i){return T(),L("span",J({class:e.cx("root"),"data-p":i.dataP},e.ptmi("root")),[We(e.$slots,"default",{},function(){return[Ge(X(e.value),1)]})],16,zr)}zn.render=Wr;function at(e){"@babel/helpers - typeof";return at=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},at(e)}function yn(e,t){return Fr(e)||Kr(e,t)||Hr(e,t)||qr()}function qr(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Hr(e,t){if(e){if(typeof e=="string")return _n(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?_n(e,t):void 0}}function _n(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Kr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t!==0)for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function Fr(e){if(Array.isArray(e))return e}function Sn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function x(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Sn(Object(n),!0).forEach(function(o){Ut(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Sn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ut(e,t,n){return(t=Gr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Gr(e){var t=Yr(e,"string");return at(t)=="symbol"?t:t+""}function Yr(e,t){if(at(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(at(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var w={_getMeta:function(){return[fe(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],ie(fe(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(t,n){var o,r,i;return(o=(t==null||(r=t.instance)===null||r===void 0?void 0:r.$primevue)||(n==null||(i=n.ctx)===null||i===void 0||(i=i.appContext)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.globalProperties)===null||i===void 0?void 0:i.$primevue))===null||o===void 0?void 0:o.config},_getOptionValue:Ht,_getPTValue:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},i=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",s=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},l=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,a=function(){var O=w._getOptionValue.apply(w,arguments);return ne(O)||xn(O)?{class:O}:O},u=((t=o.binding)===null||t===void 0||(t=t.value)===null||t===void 0?void 0:t.ptOptions)||((n=o.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},d=u.mergeSections,c=d===void 0?!0:d,p=u.mergeProps,m=p===void 0?!1:p,b=l?w._useDefaultPT(o,o.defaultPT(),a,i,s):void 0,_=w._usePT(o,w._getPT(r,o.$name),a,i,x(x({},s),{},{global:b||{}})),h=w._getPTDatasets(o,i);return c||!c&&_?m?w._mergeProps(o,m,b,_,h):x(x(x({},b),_),h):x(x({},_),h)},_getPTDatasets:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o="data-pc-";return x(x({},n==="root"&&Ut({},"".concat(o,"name"),me(t.$name))),{},Ut({},"".concat(o,"section"),me(n)))},_getPT:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,r=function(s){var l,a=o?o(s):s,u=me(n);return(l=a?.[u])!==null&&l!==void 0?l:a};return t&&Object.hasOwn(t,"_usept")?{_usept:t._usept,originalValue:r(t.originalValue),value:r(t.value)}:r(t)},_usePT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0,s=function(h){return o(h,r,i)};if(n&&Object.hasOwn(n,"_usept")){var l,a=n._usept||((l=t.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},u=a.mergeSections,d=u===void 0?!0:u,c=a.mergeProps,p=c===void 0?!1:c,m=s(n.originalValue),b=s(n.value);return m===void 0&&b===void 0?void 0:ne(b)?b:ne(m)?m:d||!d&&b?p?w._mergeProps(t,p,m,b):x(x({},m),b):b}return s(n)},_useDefaultPT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0;return w._usePT(t,n,o,r,i)},_loadStyles:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,i=w._getConfig(o,r),s={nonce:i==null||(t=i.csp)===null||t===void 0?void 0:t.nonce};w._loadCoreStyles(n,s),w._loadThemeStyles(n,s),w._loadScopedThemeStyles(n,s),w._removeThemeListeners(n),n.$loadStyles=function(){return w._loadThemeStyles(n,s)},w._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0;if(!$e.isStyleNameLoaded((t=o.$style)===null||t===void 0?void 0:t.name)&&(n=o.$style)!==null&&n!==void 0&&n.name){var i;I.loadCSS(r),(i=o.$style)===null||i===void 0||i.loadCSS(r),$e.setLoadedStyleName(o.$style.name)}},_loadThemeStyles:function(){var t,n,o,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},i=arguments.length>1?arguments[1]:void 0;if(!(r!=null&&r.isUnstyled()||(r==null||(t=r.theme)===null||t===void 0?void 0:t.call(r))==="none")){if(!E.isStyleNameLoaded("common")){var s,l,a=((s=r.$style)===null||s===void 0||(l=s.getCommonTheme)===null||l===void 0?void 0:l.call(s))||{},u=a.primitive,d=a.semantic,c=a.global,p=a.style;I.load(u?.css,x({name:"primitive-variables"},i)),I.load(d?.css,x({name:"semantic-variables"},i)),I.load(c?.css,x({name:"global-variables"},i)),I.loadStyle(x({name:"global-style"},i),p),E.setLoadedStyleName("common")}if(!E.isStyleNameLoaded((n=r.$style)===null||n===void 0?void 0:n.name)&&(o=r.$style)!==null&&o!==void 0&&o.name){var m,b,_,h,S=((m=r.$style)===null||m===void 0||(b=m.getDirectiveTheme)===null||b===void 0?void 0:b.call(m))||{},O=S.css,C=S.style;(_=r.$style)===null||_===void 0||_.load(O,x({name:"".concat(r.$style.name,"-variables")},i)),(h=r.$style)===null||h===void 0||h.loadStyle(x({name:"".concat(r.$style.name,"-style")},i),C),E.setLoadedStyleName(r.$style.name)}if(!E.isStyleNameLoaded("layer-order")){var v,k,R=(v=r.$style)===null||v===void 0||(k=v.getLayerOrderThemeCSS)===null||k===void 0?void 0:k.call(v);I.load(R,x({name:"layer-order",first:!0},i)),E.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=t.preset();if(o&&t.$attrSelector){var r,i,s,l=((r=t.$style)===null||r===void 0||(i=r.getPresetTheme)===null||i===void 0?void 0:i.call(r,o,"[".concat(t.$attrSelector,"]")))||{},a=l.css,u=(s=t.$style)===null||s===void 0?void 0:s.load(a,x({name:"".concat(t.$attrSelector,"-").concat(t.$style.name)},n));t.scopedStyleEl=u.el}},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};$e.clearLoadedStyleNames(),W.on("theme:change",t)},_removeThemeListeners:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};W.off("theme:change",t.$loadStyles),t.$loadStyles=void 0},_hook:function(t,n,o,r,i,s){var l,a,u="on".concat(So(n)),d=w._getConfig(r,i),c=o?.$instance,p=w._usePT(c,w._getPT(r==null||(l=r.value)===null||l===void 0?void 0:l.pt,t),w._getOptionValue,"hooks.".concat(u)),m=w._useDefaultPT(c,d==null||(a=d.pt)===null||a===void 0||(a=a.directives)===null||a===void 0?void 0:a[t],w._getOptionValue,"hooks.".concat(u)),b={el:o,binding:r,vnode:i,prevVnode:s};p?.(c,b),m?.(c,b)},_mergeProps:function(){for(var t=arguments.length>1?arguments[1]:void 0,n=arguments.length,o=new Array(n>2?n-2:0),r=2;r<n;r++)o[r-2]=arguments[r];return qt(t)?t.apply(void 0,o):J.apply(void 0,o)},_extend:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=function(l,a,u,d,c){var p,m,b,_;a._$instances=a._$instances||{};var h=w._getConfig(u,d),S=a._$instances[t]||{},O=Le(S)?x(x({},n),n?.methods):{};a._$instances[t]=x(x({},S),{},{$name:t,$host:a,$binding:u,$modifiers:u?.modifiers,$value:u?.value,$el:S.$el||a||void 0,$style:x({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:h,$attrSelector:(p=a.$pd)===null||p===void 0||(p=p[t])===null||p===void 0?void 0:p.attrSelector,defaultPT:function(){return w._getPT(h?.pt,void 0,function(v){var k;return v==null||(k=v.directives)===null||k===void 0?void 0:k[t]})},isUnstyled:function(){var v,k;return((v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.unstyled)!==void 0?(k=a._$instances[t])===null||k===void 0||(k=k.$binding)===null||k===void 0||(k=k.value)===null||k===void 0?void 0:k.unstyled:h?.unstyled},theme:function(){var v;return(v=a._$instances[t])===null||v===void 0||(v=v.$primevueConfig)===null||v===void 0?void 0:v.theme},preset:function(){var v;return(v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.dt},ptm:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",R=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return w._getPTValue(a._$instances[t],(v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.pt,k,x({},R))},ptmo:function(){var v=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},k=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",R=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return w._getPTValue(a._$instances[t],v,k,R,!1)},cx:function(){var v,k,R=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",U=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(v=a._$instances[t])!==null&&v!==void 0&&v.isUnstyled()?void 0:w._getOptionValue((k=a._$instances[t])===null||k===void 0||(k=k.$style)===null||k===void 0?void 0:k.classes,R,x({},U))},sx:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",R=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,U=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return R?w._getOptionValue((v=a._$instances[t])===null||v===void 0||(v=v.$style)===null||v===void 0?void 0:v.inlineStyles,k,x({},U)):void 0}},O),a.$instance=a._$instances[t],(m=(b=a.$instance)[l])===null||m===void 0||m.call(b,a,u,d,c),a["$".concat(t)]=a.$instance,w._hook(t,l,a,u,d,c),a.$pd||(a.$pd={}),a.$pd[t]=x(x({},(_=a.$pd)===null||_===void 0?void 0:_[t]),{},{name:t,instance:a._$instances[t]})},r=function(l){var a,u,d,c=l._$instances[t],p=c?.watch,m=function(h){var S,O=h.newValue,C=h.oldValue;return p==null||(S=p.config)===null||S===void 0?void 0:S.call(c,O,C)},b=function(h){var S,O=h.newValue,C=h.oldValue;return p==null||(S=p["config.ripple"])===null||S===void 0?void 0:S.call(c,O,C)};c.$watchersCallback={config:m,"config.ripple":b},p==null||(a=p.config)===null||a===void 0||a.call(c,c?.$primevueConfig),Pe.on("config:change",m),p==null||(u=p["config.ripple"])===null||u===void 0||u.call(c,c==null||(d=c.$primevueConfig)===null||d===void 0?void 0:d.ripple),Pe.on("config:ripple:change",b)},i=function(l){var a=l._$instances[t].$watchersCallback;a&&(Pe.off("config:change",a.config),Pe.off("config:ripple:change",a["config.ripple"]),l._$instances[t].$watchersCallback=void 0)};return{created:function(l,a,u,d){l.$pd||(l.$pd={}),l.$pd[t]={name:t,attrSelector:No("pd")},o("created",l,a,u,d)},beforeMount:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("beforeMount",l,a,u,d),r(l)},mounted:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("mounted",l,a,u,d)},beforeUpdate:function(l,a,u,d){o("beforeUpdate",l,a,u,d)},updated:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("updated",l,a,u,d)},beforeUnmount:function(l,a,u,d){var c;i(l),w._removeThemeListeners((c=l.$pd[t])===null||c===void 0?void 0:c.instance),o("beforeUnmount",l,a,u,d)},unmounted:function(l,a,u,d){var c;(c=l.$pd[t])===null||c===void 0||(c=c.instance)===null||c===void 0||(c=c.scopedStyleEl)===null||c===void 0||(c=c.value)===null||c===void 0||c.remove(),o("unmounted",l,a,u,d)}}},extend:function(){var t=w._getMeta.apply(w,arguments),n=yn(t,2),o=n[0],r=n[1];return x({extend:function(){var s=w._getMeta.apply(w,arguments),l=yn(s,2),a=l[0],u=l[1];return w.extend(a,x(x(x({},r),r?.methods),u))}},w._extend(o,r))}},Qr=`
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
`,Zr={root:"p-ink"},Jr=I.extend({name:"ripple-directive",style:Qr,classes:Zr}),Xr=w.extend({style:Jr});function it(e){"@babel/helpers - typeof";return it=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},it(e)}function ea(e){return ra(e)||oa(e)||na(e)||ta()}function ta(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function na(e,t){if(e){if(typeof e=="string")return zt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?zt(e,t):void 0}}function oa(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function ra(e){if(Array.isArray(e))return zt(e)}function zt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function kn(e,t,n){return(t=aa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function aa(e){var t=ia(e,"string");return it(t)=="symbol"?t:t+""}function ia(e,t){if(it(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(it(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var sa=Xr.extend("ripple",{watch:{"config.ripple":function(t){t?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(t){this.remove(t)},timeout:void 0,methods:{bindEvents:function(t){t.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(t){t.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(t){var n=this.getInk(t);n||(n=To("span",kn(kn({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),t.appendChild(n),this.$el=n)},remove:function(t){var n=this.getInk(t);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(t),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(t){var n=this,o=t.currentTarget,r=this.getInk(o);if(!(!r||getComputedStyle(r,null).display==="none")){if(!this.isUnstyled()&&Et(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"),!Xt(r)&&!en(r)){var i=Math.max($o(o),Lo(o));r.style.height=i+"px",r.style.width=i+"px"}var s=Ao(o),l=t.pageX-s.left+document.body.scrollTop-en(r)/2,a=t.pageY-s.top+document.body.scrollLeft-Xt(r)/2;r.style.top=a+"px",r.style.left=l+"px",!this.isUnstyled()&&wo(r,"p-ink-active"),r.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){r&&(!n.isUnstyled()&&Et(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(t){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&Et(t.currentTarget,"p-ink-active"),t.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(t){return t&&t.children?ea(t.children).find(function(n){return Co(n,"data-pc-name")==="ripple"}):void 0}}}),la=`
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
`;function st(e){"@babel/helpers - typeof";return st=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},st(e)}function pe(e,t,n){return(t=ua(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function ua(e){var t=da(e,"string");return st(t)=="symbol"?t:t+""}function da(e,t){if(st(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(st(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var ca={root:function(t){var n=t.instance,o=t.props;return["p-button p-component",pe(pe(pe(pe(pe(pe(pe(pe(pe({"p-button-icon-only":n.hasIcon&&!o.label&&!o.badge,"p-button-vertical":(o.iconPos==="top"||o.iconPos==="bottom")&&o.label,"p-button-loading":o.loading,"p-button-link":o.link||o.variant==="link"},"p-button-".concat(o.severity),o.severity),"p-button-raised",o.raised),"p-button-rounded",o.rounded),"p-button-text",o.text||o.variant==="text"),"p-button-outlined",o.outlined||o.variant==="outlined"),"p-button-sm",o.size==="small"),"p-button-lg",o.size==="large"),"p-button-plain",o.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(t){var n=t.props;return["p-button-icon",pe({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},pa=I.extend({name:"button",style:la,classes:ca}),ma={name:"BaseButton",extends:Kt,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:pa,provide:function(){return{$pcButton:this,$parentInstance:this}}};function lt(e){"@babel/helpers - typeof";return lt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},lt(e)}function Z(e,t,n){return(t=fa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function fa(e){var t=ba(e,"string");return lt(t)=="symbol"?t:t+""}function ba(e,t){if(lt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(lt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var ut={name:"Button",extends:ma,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(t){var n=t==="root"?this.ptmi:this.ptm;return n(t,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return J(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return Le(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return Fe(Z(Z(Z(Z(Z(Z(Z(Z(Z(Z({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return Fe(Z(Z({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return Fe(Z(Z({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:Un,Badge:zn},directives:{ripple:sa}},va=["data-p"],ga=["data-p"];function ha(e,t,n,o,r,i){var s=Rt("SpinnerIcon"),l=Rt("Badge"),a=eo("ripple");return e.asChild?We(e.$slots,"default",{key:1,class:Ve(e.cx("root")),a11yAttrs:i.a11yAttrs}):to((T(),Re(no(e.as),J({key:0,class:e.cx("root"),"data-p":i.dataP},i.attrs),{default:Ye(function(){return[We(e.$slots,"default",{},function(){return[e.loading?We(e.$slots,"loadingicon",J({key:0,class:[e.cx("loadingIcon"),e.cx("icon")]},e.ptm("loadingIcon")),function(){return[e.loadingIcon?(T(),L("span",J({key:0,class:[e.cx("loadingIcon"),e.cx("icon"),e.loadingIcon]},e.ptm("loadingIcon")),null,16)):(T(),Re(s,J({key:1,class:[e.cx("loadingIcon"),e.cx("icon")],spin:""},e.ptm("loadingIcon")),null,16,["class"]))]}):We(e.$slots,"icon",J({key:1,class:[e.cx("icon")]},e.ptm("icon")),function(){return[e.icon?(T(),L("span",J({key:0,class:[e.cx("icon"),e.icon,e.iconClass],"data-p":i.dataIconP},e.ptm("icon")),null,16,va)):te("",!0)]}),e.label?(T(),L("span",J({key:2,class:e.cx("label")},e.ptm("label"),{"data-p":i.dataLabelP}),X(e.label),17,ga)):te("",!0),e.badge?(T(),Re(l,{key:3,value:e.badge,class:Ve(e.badgeClass),severity:e.badgeSeverity,unstyled:e.unstyled,pt:e.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):te("",!0)]})]}),_:3},16,["class","data-p"])),[[a]])}ut.render=ha;const Wn=Symbol("host_api"),qn=Symbol("axios"),Hn=Symbol("proxy"),ya=Symbol("config"),_a=Symbol("on_subscription");function Sa(){const e=Wt(Wn);if(!e)throw new Error("HostApi not provided");return e}function ka(){const e=Wt(qn);if(!e)throw new Error("ProxyApiInstance not provided");return e}function wa(){const e=Wt(Hn);if(!e)throw new Error("WIPPY_INSTANCE not provided");return e}async function hi(e){const{data:t}=await e.get("/api/v1/keeper/registry/namespaces");return t}async function yi(e,t={}){const n={limit:t.limit||200,offset:t.offset||0};t.namespace&&(n.namespace=t.namespace),t.kind&&(n.kind=t.kind),t.metaType&&(n["meta.type"]=t.metaType),t.query&&(n.q=t.query);const{data:o}=await e.get("/api/v1/keeper/registry/entries",{params:n});return o}async function _i(e,t){const{data:n}=await e.get("/api/v1/keeper/registry/entry",{params:{id:t}});return n}async function Si(e,t,n){const{data:o}=await e.put("/api/v1/keeper/registry/entry",n,{params:{id:t}});return o}async function ki(e,t){const n={};t&&(n.namespace=t);const{data:o}=await e.get("/api/v1/keeper/state/graph",{params:n});return o}async function wi(e){const{data:t}=await e.get("/api/v1/keeper/env/list");return t}async function $i(e,t,n){const{data:o}=await e.post("/api/v1/keeper/env/set",{key:t,value:n});return o}async function Pi(e){const{data:t}=await e.get("/api/v1/keeper/sync/state");return t}async function Oi(e){const{data:t}=await e.get("/api/v1/keeper/sync/config");return t}async function Ti(e,t){const{data:n}=await e.put("/api/v1/keeper/sync/config",{managed_namespaces:t});return n}async function xi(e){const{data:t}=await e.post("/api/v1/keeper/sync/download");return t}async function Ci(e){const{data:t}=await e.post("/api/v1/keeper/sync/upload");return t}async function Ai(e){const{data:t}=await e.post("/api/v1/keeper/sync/undo");return t}async function Li(e){const{data:t}=await e.post("/api/v1/keeper/sync/redo");return t}const It={"ns.definition":"var(--p-info-500)","ns.requirement":"var(--p-warn-500)","ns.dependency":"var(--p-accent-400)","http.service":"var(--p-success-500)","http.router":"var(--p-success-500)","http.endpoint":"var(--p-info-500)","http.static":"var(--p-info-500)","function.lua":"var(--p-warn-500)","library.lua":"var(--p-warn-500)","process.lua":"var(--p-warn-500)","registry.entry":"var(--p-accent-500)","db.sql.sqlite":"var(--p-accent-500)","fs.directory":"var(--p-text-muted-color)","fs.embed":"var(--p-text-muted-color)","process.host":"var(--p-info-500)","store.memory":"var(--p-accent-500)","store.sql":"var(--p-accent-500)","env.variable":"var(--p-text-muted-color)","env.composite":"var(--p-text-muted-color)","env.file":"var(--p-text-muted-color)","env.os":"var(--p-text-muted-color)","env.memory":"var(--p-text-muted-color)","security.policy":"var(--p-danger-500)","view.page":"var(--p-info-500)","view.component":"var(--p-info-500)","queue.memory":"var(--p-accent-500)","queue.consumer":"var(--p-accent-500)","template.set":"var(--p-warn-500)",contract:"var(--p-accent-400)","agent.gen1":"var(--p-warn-500)","agent.trait":"var(--p-warn-500)","llm.model":"var(--p-accent-500)",tool:"var(--p-info-500)"},Dt={"ns.definition":"tabler:package","ns.requirement":"tabler:plug","ns.dependency":"tabler:link","http.service":"tabler:server","http.router":"tabler:route","http.endpoint":"tabler:api","http.static":"tabler:file","function.lua":"tabler:code","library.lua":"tabler:book","process.lua":"tabler:code","registry.entry":"tabler:database","db.sql.sqlite":"tabler:database","fs.directory":"tabler:folder","fs.embed":"tabler:folder","process.host":"tabler:cpu","store.memory":"tabler:database","store.sql":"tabler:database","env.variable":"tabler:variable","env.composite":"tabler:variable","env.file":"tabler:variable","env.os":"tabler:variable","env.memory":"tabler:variable","security.policy":"tabler:shield-check","view.page":"tabler:browser","view.component":"tabler:components","queue.memory":"tabler:list","queue.consumer":"tabler:player-play","template.set":"tabler:template",contract:"tabler:file-certificate","agent.gen1":"tabler:robot","agent.trait":"tabler:sparkles","llm.model":"tabler:brain",tool:"tabler:tool"};function _t(e,t){return t&&It[t]?It[t]:It[e]||"var(--p-text-muted-color)"}function Kn(e,t){return t&&Dt[t]?Dt[t]:Dt[e]||"tabler:circle"}async function Ei(e,t=100,n=0){const{data:o}=await e.get("/api/v1/sessions",{params:{limit:t,offset:n}});return o}async function ji(e,t){const{data:n}=await e.get("/api/v1/sessions/get",{params:{session_id:t}});return n}async function Ni(e,t,n=50,o=""){const{data:r}=await e.get("/api/v1/sessions/messages",{params:{session_id:t,limit:n,cursor:o}});return r}function Ii(e){return!e||e===0?"0":e>=1e6?(e/1e6).toFixed(1)+"M":e>=1e3?(e/1e3).toFixed(1)+"K":e.toString()}function wn(e){if(!e)return"";let t;typeof e=="number"?e>1e15?t=e/1e6:e>1e12?t=e/1e3:e>1e10?t=e:t=e*1e3:t=new Date(e).getTime();const n=new Date(t);if(isNaN(n.getTime()))return"";const r=Math.floor((new Date().getTime()-n.getTime())/1e3);if(r<60)return"just now";const i=Math.floor(r/60);if(i<60)return`${i}m ago`;const s=Math.floor(i/60);if(s<24)return`${s}h ago`;const l=Math.floor(s/24);if(l<30)return`${l}d ago`;const a=Math.floor(l/30);return a<12?`${a}mo ago`:`${Math.floor(a/12)}y ago`}function Di(e){return e?new Date(typeof e=="number"?e*1e3:e).toLocaleString():"N/A"}const $a={key:0,class:"status-dropdown"},Pa=["onClick"],Oa={key:0,class:"plugin-tag",title:"Provided by a registered plugin"},Ta=Ae({__name:"AppNavDropdown",props:{icon:{},label:{},items:{},open:{type:Boolean},active:{type:Boolean},currentName:{},wrapClass:{}},emits:["toggle","navigate"],setup(e,{emit:t}){const n=t;function o(r){n("navigate",r)}return(r,i)=>(T(),L("div",{class:Ve(["relative",e.wrapClass])},[j(D(ut),{variant:"text",class:Ve(["k-btn-nav relative !gap-1.5",{"k-btn-active":e.active}]),onClick:i[0]||(i[0]=s=>n("toggle"))},{default:Ye(()=>[j(D(ee),{icon:e.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Ge(" "+X(e.label)+" ",1),j(D(ee),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.5"}})]),_:1},8,["class"]),e.open?(T(),L("div",$a,[(T(!0),L(Qe,null,Ze(e.items,s=>(T(),L("button",{key:s.name,class:Ve(["status-item",{"status-item--active":e.currentName===s.name}]),onClick:l=>o(s.path)},[j(D(ee),{icon:s.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Ge(" "+X(s.label)+" ",1),s.name.startsWith("plugin:")?(T(),L("span",Oa,"plugin")):te("",!0)],10,Pa))),128))])):te("",!0)],2))}}),Fn=(e,t)=>{const n=e.__vccOpts||e;for(const[o,r]of t)n[o]=r;return n},ze=Fn(Ta,[["__scopeId","data-v-6d403115"]]),xa={class:"truncate",style:{"max-width":"80px"}},Ca={key:1,class:"relative agent-dropdown-wrap"},Aa={key:0,class:"agent-dropdown"},La=["onClick"],Ea={class:"agent-item-copy"},ja={class:"agent-item-title"},Na={key:0,class:"agent-item-comment"},Ia=Ae({__name:"AppAgentLauncher",props:{agents:{},open:{type:Boolean}},emits:["toggle","start"],setup(e,{emit:t}){const n=t;return(o,r)=>e.agents.length===1?(T(),L("button",{key:0,class:"ask-btn",onClick:r[0]||(r[0]=i=>n("start",e.agents[0].start_token))},[j(D(ee),{icon:e.agents[0].icon||"tabler:message-bolt",class:"w-3.5 h-3.5"},null,8,["icon"]),M("span",xa,X(e.agents[0].title||"Ask"),1)])):e.agents.length>1?(T(),L("div",Ca,[M("button",{class:"ask-btn",onClick:r[1]||(r[1]=i=>n("toggle"))},[j(D(ee),{icon:"tabler:message-bolt",class:"w-3.5 h-3.5"}),r[2]||(r[2]=Ge(" Ask ",-1)),j(D(ee),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.6"}})]),e.open?(T(),L("div",Aa,[(T(!0),L(Qe,null,Ze(e.agents,i=>(T(),L("button",{key:i.id,class:"agent-item",onClick:s=>n("start",i.start_token)},[j(D(ee),{icon:i.icon||"tabler:robot",class:"agent-item-icon"},null,8,["icon"]),M("span",Ea,[M("span",ja,X(i.title||i.id),1),i.comment?(T(),L("span",Na,X(i.comment),1)):te("",!0)])],8,La))),128))])):te("",!0)])):te("",!0)}}),Da=Fn(Ia,[["__scopeId","data-v-eeb14e8e"]]),Ra={key:0,class:"flex items-center gap-1.5 text-xs pl-2",style:{color:"var(--p-text-muted-color)","border-left":"1px solid var(--p-content-border-color)"}},Va={class:"truncate max-w-[100px]"},Ma=Ae({__name:"AppUserChip",props:{user:{}},emits:["logout"],setup(e,{emit:t}){const n=t;return(o,r)=>e.user?(T(),L("div",Ra,[M("span",Va,X(e.user.full_name||e.user.email),1),j(D(ut),{class:"k-btn-icon !w-6 !h-6 !p-0 !rounded-full",title:"Logout",onClick:r[0]||(r[0]=i=>n("logout"))},{default:Ye(()=>[j(D(ee),{icon:"tabler:logout",class:"w-3 h-3"})]),_:1})])):te("",!0)}}),Ba={class:"search-modal"},Ua={class:"search-header"},za=["value"],Wa={key:0,class:"search-results"},qa=["onClick"],Ha={class:"flex-1 min-w-0"},Ka={class:"text-[11px] font-mono truncate",style:{color:"var(--p-text-color)"}},Fa={key:0,class:"text-[9px] truncate",style:{color:"var(--p-text-muted-color)"}},Ga={key:1,class:"search-empty"},Ya={key:2,class:"search-hints"},Qa=["onClick"],Za={class:"text-[10px] font-mono",style:{color:"var(--p-primary-color)"}},Ja={class:"text-[10px]",style:{color:"var(--p-text-muted-color)"}},Xa=Ae({__name:"AppGlobalSearch",props:{open:{type:Boolean},query:{},results:{},loading:{type:Boolean},hints:{}},emits:["update:query","close","search-input","select","apply-hint"],setup(e,{emit:t}){const n=t;function o(r){r.length>0&&n("select",r[0])}return(r,i)=>(T(),Re(oo,{to:"body"},[e.open?(T(),L("div",{key:0,class:"search-overlay",onClick:i[3]||(i[3]=ro(s=>n("close"),["self"]))},[M("div",Ba,[M("div",Ua,[j(D(ee),{icon:"tabler:search",class:"w-4 h-4 shrink-0",style:{color:"var(--p-text-muted-color)"}}),M("input",{value:e.query,onInput:i[0]||(i[0]=s=>{n("update:query",s.target.value),n("search-input")}),onKeydown:[i[1]||(i[1]=Gt(s=>n("close"),["escape"])),i[2]||(i[2]=Gt(s=>o(e.results),["enter"]))],class:"global-search-input",placeholder:"Search entries, functions, configs...",autofocus:""},null,40,za),e.loading?(T(),Re(D(ee),{key:0,icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin",style:{color:"var(--p-primary-color)"}})):te("",!0),i[4]||(i[4]=M("kbd",{class:"search-kbd"},"Esc",-1))]),e.results.length>0?(T(),L("div",Wa,[(T(!0),L(Qe,null,Ze(e.results,s=>(T(),L("div",{key:s.id,class:"search-item",onClick:l=>n("select",s)},[j(D(ee),{icon:s.icon||D(Kn)(s.kind),class:"w-3 h-3 shrink-0",style:Yt({color:s.color||D(_t)(s.kind)})},null,8,["icon","style"]),M("div",Ha,[M("div",Ka,X(s.id),1),s.snippet?(T(),L("div",Fa,X(s.snippet),1)):te("",!0)]),M("span",{class:"text-[8px] px-1 rounded",style:Yt({color:s.color||D(_t)(s.kind),background:`color-mix(in srgb, ${s.color||D(_t)(s.kind)} 12%, transparent)`})},X(s.kind),5)],8,qa))),128))])):e.query&&!e.loading?(T(),L("div",Ga,"No results")):e.query?te("",!0):(T(),L("div",Ya,[(T(!0),L(Qe,null,Ze(e.hints,s=>(T(),L("div",{key:s.prefix,class:"search-hint",onClick:l=>n("apply-hint",s.prefix)},[j(D(ee),{icon:s.icon,class:"w-3 h-3 shrink-0",style:{color:"var(--p-text-muted-color)"}},null,8,["icon"]),M("span",Za,X(s.prefix||"*"),1),M("span",Ja,X(s.desc),1)],8,Qa))),128))]))])])):te("",!0)]))}}),ei={class:"h-full flex flex-col"},ti={class:"shrink-0 h-10 flex items-center px-3 gap-3",style:{background:"var(--p-content-background)","border-bottom":"1px solid var(--p-content-border-color)"}},ni={class:"flex items-center gap-0.5 flex-1"},oi={class:"flex items-center gap-1.5 shrink-0"},ri={class:"flex-1 overflow-y-auto",style:{background:"color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)"}},ai=Ae({__name:"app",setup(e){const t=On(),n=so(),o=ka(),r=Sa(),i=wa(),s=B(0),l=B(0);let a=null,u=null;async function d(){try{const{data:f}=await o.get("/api/v1/keeper/logger/stats");f.success&&f.stats?.counters&&(s.value=f.stats.counters.error||0,l.value=f.stats.counters.warn||0)}catch{}}const c=[{path:"/",name:"dashboard",label:"Home",icon:"tabler:layout-dashboard"}],p=[{path:"/settings/environment",name:"settings-environment",label:"Environment",icon:"tabler:variable"},{path:"/settings/registry",name:"settings-registry",label:"Registry",icon:"tabler:database"},{path:"/settings/hub",name:"settings-hub",label:"Wippy Hub",icon:"tabler:cloud"},{path:"/mcp",name:"mcp",label:"MCP",icon:"tabler:plug-connected"}],m=[{path:"/sessions",name:"sessions",label:"Sessions",icon:"tabler:list"},{path:"/dataflows",name:"workflow",label:"Dataflows",icon:"tabler:git-merge"},{path:"/system",name:"system",label:"System",icon:"tabler:activity"},{path:"/logs",name:"logs",label:"Logs",icon:"tabler:file-text"}],b=[],_=[{path:"/structure",name:"structure",label:"Registry",icon:"tabler:binary-tree"},{path:"/agents",name:"agents",label:"Agents",icon:"tabler:robot"},{path:"/models",name:"models",label:"Models",icon:"tabler:brain"},{path:"/tools",name:"tools",label:"Tools",icon:"tabler:tool"},{path:"/traits",name:"traits",label:"Traits",icon:"tabler:sparkles"},{path:"/endpoints",name:"endpoints",label:"Endpoints",icon:"tabler:api"},{path:"/policies",name:"policies",label:"Policies",icon:"tabler:shield-check"}],h=[{path:"/tasks",name:"tasks",label:"Pipeline",icon:"tabler:git-merge"},{path:"/changes",name:"changes",label:"Changes",icon:"tabler:git-branch"},{path:"/components",name:"components",label:"Components",icon:"tabler:puzzle"},{path:"/knowledge",name:"knowledge",label:"Knowledge",icon:"tabler:brain"},{path:"/tests",name:"tests",label:"Tests",icon:"tabler:test-pipe"}],S=B([]);async function O(){try{const{data:f}=await o.get("/api/public/pages/list");if(!f?.success||!Array.isArray(f.pages))return;S.value=f.pages.filter(g=>g.announced&&g.id.startsWith("keeper.")&&g.id!=="keeper:main").sort((g,ae)=>(g.order||9999)-(ae.order||9999)||g.title.localeCompare(ae.title)).map(g=>({path:`/plugin/${g.id}`,name:`plugin:${g.id}`,label:g.title||g.name,icon:g.icon||"tabler:puzzle",group:g.group||"develop"}))}catch{}}const C=H(()=>[...m,...S.value.filter(f=>f.group==="observe")]),v=H(()=>[..._,...S.value.filter(f=>f.group==="structure")]),k=H(()=>[...h,...S.value.filter(f=>f.group==="develop"||!f.group)]),R=H(()=>[...b,...S.value.filter(f=>f.group==="status")]),U=B(!1),K=B(!1),F=B(!1),oe=B(!1),G=B(!1),Y=B(!1),be=H(()=>new Set(R.value.map(f=>f.name))),ce=H(()=>new Set(v.value.map(f=>f.name))),ve=H(()=>new Set(k.value.map(f=>f.name))),Se=H(()=>new Set(C.value.map(f=>f.name))),ge=H(()=>new Set(p.map(f=>f.name))),V=H(()=>n.name),ke=H(()=>be.value.has(String(V.value))),le=H(()=>ce.value.has(String(V.value))),se=H(()=>ve.value.has(String(V.value))),he=H(()=>Se.value.has(String(V.value))||V.value==="session-detail"||V.value==="dataflow-detail"),Ee=H(()=>ge.value.has(String(V.value))||V.value==="settings"),ye=B(null);function je(f){t.push(f)}function ct(){U.value=!1,K.value=!1,F.value=!1,oe.value=!1,G.value=!1,Y.value=!1}function Oe(f){je(f),ct()}async function $t(){try{const{data:f}=await o.get("/api/v1/user/me");f.success&&f.user&&(ye.value={email:f.user.email,full_name:f.user.full_name})}catch{}}const pt=B([]);async function Pt(){try{const{data:f}=await o.get("/api/v1/keeper/agents/list",{params:{public_only:!0}});pt.value=f.agents||[]}catch{}}function Ot(f){r.startChat(f,{sidebar:!0}),Y.value=!1}const we=B(!1),Te=B(""),re=B([]),Me=B(!1);let Be=null;const Tt=[{prefix:"session:",desc:"Search sessions by title or ID",icon:"tabler:list"},{prefix:"dataflow:",desc:"Search dataflows",icon:"tabler:git-merge"},{prefix:"agent:",desc:"Search agents",icon:"tabler:robot"},{prefix:"model:",desc:"Search LLM models",icon:"tabler:brain"},{prefix:"tool:",desc:"Search tools",icon:"tabler:tool"},{prefix:"endpoint:",desc:"Search HTTP endpoints",icon:"tabler:api"},{prefix:"",desc:"Search all registry entries",icon:"tabler:search"}];async function mt(){const f=Te.value.trim();if(!f){re.value=[];return}Me.value=!0;try{const g=f.indexOf(":"),ae=g>0?f.slice(0,g).toLowerCase():"",$=g>0?f.slice(g+1).trim():f;if(ae==="session"){const{data:Q}=await o.get("/api/v1/sessions",{params:{limit:20}}),z=(Q.sessions||[]).filter(y=>!$||y.title?.toLowerCase().includes($.toLowerCase())||y.session_id?.includes($)||y.current_agent?.toLowerCase().includes($.toLowerCase()));re.value=z.slice(0,15).map(y=>({id:y.title||y.session_id?.slice(0,12)+"...",kind:y.current_agent||"session",snippet:[y.current_model,y.status,wn(y.last_message_date||y.start_date)].filter(Boolean).join(" · "),icon:"tabler:message",color:"var(--p-info-500)",route:"/session/"+y.session_id}))}else if(ae==="dataflow"){const{data:Q}=await o.get("/api/v1/dataflows",{params:{limit:20}}),z=(Q.dataflows||[]).filter(y=>!$||y.metadata?.title?.toLowerCase().includes($.toLowerCase())||y.dataflow_id?.includes($));re.value=z.slice(0,15).map(y=>({id:y.metadata?.title||y.dataflow_id?.slice(0,12)+"...",kind:y.status||"dataflow",snippet:[y.type,wn(y.created_at)].filter(Boolean).join(" · "),icon:"tabler:git-merge",color:y.status==="running"?"var(--p-success-500)":y.status==="failed"?"var(--p-danger-500)":"var(--p-info-500)",route:"/dataflow/"+y.dataflow_id}))}else if(ae==="agent"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"agent.gen1",limit:100}}),z=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));re.value=z.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.title||"",icon:"tabler:robot",color:"var(--p-warn-500)",route:"/structure?entry="+y.id}))}else if(ae==="model"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"llm.model",limit:100}}),z=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));re.value=z.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.title||"",icon:"tabler:brain",color:"var(--p-accent-500)",route:"/structure?entry="+y.id}))}else if(ae==="tool"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"tool",limit:100}}),z=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));re.value=z.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.comment||y.meta?.llm_alias||"",icon:"tabler:tool",color:"var(--p-info-500)",route:"/structure?entry="+y.id}))}else if(ae==="endpoint"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{kind:"http.endpoint",limit:200}}),z=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase()));re.value=z.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.comment||"",icon:"tabler:api",color:"var(--p-info-500)",route:"/structure?entry="+y.id}))}else{const{data:Q}=await o.get("/api/v1/keeper/state/search",{params:{q:f,limit:30}});re.value=(Q.results||[]).map(z=>({id:z.id,kind:z.kind,snippet:z.snippet,icon:Kn(z.kind),color:_t(z.kind),route:"/structure?entry="+z.id}))}}catch{re.value=[]}finally{Me.value=!1}}function xt(){Be&&clearTimeout(Be),Be=window.setTimeout(mt,300)}function Ct(f){Te.value=f,mt(),window.setTimeout(()=>{const g=document.querySelector(".global-search-input");g&&(g.focus(),g.setSelectionRange(f.length,f.length))},10)}function At(f){if(we.value=!1,Te.value="",re.value=[],f.route)if(f.route.includes("?")){const[g,ae]=f.route.split("?"),$=Object.fromEntries(new URLSearchParams(ae));t.push({path:g,query:$})}else t.push(f.route)}function ft(f){(f.ctrlKey||f.metaKey)&&f.shiftKey&&(f.key==="F"||f.key==="f")&&(f.preventDefault(),we.value=!0,setTimeout(()=>document.querySelector(".global-search-input")?.focus(),50)),f.key==="Escape"&&we.value&&(we.value=!1)}function Lt(){r.logout()}Ie(()=>n.fullPath,()=>{try{const f={page:n.name,path:n.fullPath};n.query.entry&&(f.selected_entry=n.query.entry),n.query.ns&&(f.namespace=n.query.ns),r.setContext(f)}catch{}});function bt(f){const g=f.target;g.closest(".status-dropdown-wrap")||(U.value=!1),g.closest(".structure-dropdown-wrap")||(K.value=!1),g.closest(".develop-dropdown-wrap")||(F.value=!1),g.closest(".observe-dropdown-wrap")||(oe.value=!1),g.closest(".settings-dropdown-wrap")||(G.value=!1),g.closest(".agent-dropdown-wrap")||(Y.value=!1)}return Pn(()=>{a=i.on("action:navigate",f=>{const g=f?.data?.path||f?.path;g&&t.push(g)}),u=i.on("keeper.logs",f=>{const g=f?.data?.counters||f?.counters;g&&(s.value=g.error||0,l.value=g.warn||0)}),$t(),d(),Pt(),O(),document.addEventListener("click",bt),document.addEventListener("keydown",ft)}),ao(()=>{a?.(),u?.(),document.removeEventListener("click",bt),document.removeEventListener("keydown",ft)}),(f,g)=>{const ae=Rt("router-view");return T(),L("div",ei,[M("header",ti,[j(D(ut),{variant:"text",class:"shrink-0 !gap-1.5",onClick:g[0]||(g[0]=$=>je("/"))},{default:Ye(()=>[j(D(ee),{icon:"tabler:shield-code",class:"w-4 h-4"}),g[9]||(g[9]=M("span",{class:"text-xs font-bold tracking-wider font-mono"},"KEEPER",-1))]),_:1}),M("nav",ni,[(T(),L(Qe,null,Ze(c,$=>j(D(ut),{key:$.name,variant:"text",class:Ve(["k-btn-nav relative !gap-1.5",{"k-btn-active":V.value===$.name}]),onClick:Q=>je($.path)},{default:Ye(()=>[j(D(ee),{icon:$.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Ge(" "+X($.label),1)]),_:2},1032,["class","onClick"])),64)),j(ze,{icon:"tabler:eye",label:"Observe","wrap-class":"observe-dropdown-wrap",items:C.value,open:oe.value,active:he.value,"current-name":V.value,onToggle:g[1]||(g[1]=$=>oe.value=!oe.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),j(ze,{icon:"tabler:binary-tree",label:"Structure","wrap-class":"structure-dropdown-wrap",items:v.value,open:K.value,active:le.value,"current-name":V.value,onToggle:g[2]||(g[2]=$=>K.value=!K.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),j(ze,{icon:"tabler:code",label:"Develop","wrap-class":"develop-dropdown-wrap",items:k.value,open:F.value,active:se.value,"current-name":V.value,onToggle:g[3]||(g[3]=$=>F.value=!F.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),R.value.length?(T(),Re(ze,{key:0,icon:"tabler:heart-rate-monitor",label:"Status","wrap-class":"status-dropdown-wrap",items:R.value,open:U.value,active:ke.value,"current-name":V.value,onToggle:g[4]||(g[4]=$=>U.value=!U.value),onNavigate:Oe},null,8,["items","open","active","current-name"])):te("",!0),j(ze,{icon:"tabler:settings",label:"Settings","wrap-class":"settings-dropdown-wrap",items:p,open:G.value,active:Ee.value,"current-name":V.value,onToggle:g[5]||(g[5]=$=>G.value=!G.value),onNavigate:Oe},null,8,["open","active","current-name"])]),M("div",oi,[j(Da,{agents:pt.value,open:Y.value,onToggle:g[6]||(g[6]=$=>Y.value=!Y.value),onStart:Ot},null,8,["agents","open"]),j(Ma,{user:ye.value,onLogout:Lt},null,8,["user"])])]),M("main",ri,[j(ae)]),j(Xa,{open:we.value,query:Te.value,results:re.value,loading:Me.value,hints:Tt,"onUpdate:query":g[7]||(g[7]=$=>Te.value=$),onClose:g[8]||(g[8]=$=>we.value=!1),onSearchInput:xt,onSelect:At,onApplyHint:Ct},null,8,["open","query","results","loading"])])}}}),ii="modulepreload",si=function(e,t){return new URL(e,t).href},$n={},A=function(t,n,o){let r=Promise.resolve();if(n&&n.length>0){let s=function(d){return Promise.all(d.map(c=>Promise.resolve(c).then(p=>({status:"fulfilled",value:p}),p=>({status:"rejected",reason:p}))))};const l=document.getElementsByTagName("link"),a=document.querySelector("meta[property=csp-nonce]"),u=a?.nonce||a?.getAttribute("nonce");r=s(n.map(d=>{if(d=si(d,o),d in $n)return;$n[d]=!0;const c=d.endsWith(".css"),p=c?'[rel="stylesheet"]':"";if(!!o)for(let _=l.length-1;_>=0;_--){const h=l[_];if(h.href===d&&(!c||h.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${d}"]${p}`))return;const b=document.createElement("link");if(b.rel=c?"stylesheet":ii,c||(b.as="script"),b.crossOrigin="",b.href=d,u&&b.setAttribute("nonce",u),document.head.appendChild(b),c)return new Promise((_,h)=>{b.addEventListener("load",_),b.addEventListener("error",()=>h(new Error(`Unable to preload CSS for ${d}`)))})}))}function i(s){const l=new Event("vite:preloadError",{cancelable:!0});if(l.payload=s,window.dispatchEvent(l),!l.defaultPrevented)throw s}return r.then(s=>{for(const l of s||[])l.status==="rejected"&&i(l.reason);return t().catch(i)})};function li(e,t={}){const n=t.host??St,o=t.on===void 0?po:t.on,r=lo();t.initialPath&&r.replace(t.initialPath);const i=uo({history:r,routes:e});mo(l=>i.resolve(l));let s;return i.afterEach(l=>{const a=s;s=void 0,n.onRouteChanged(l.fullPath,a)}),o&&o("@history",({path:l,navId:a})=>{if(!l)return;a!==void 0&&(s=a);const u=l.startsWith("/")?l:`/${l}`;i.currentRoute.value.fullPath!==u&&i.push(u)}),i}Ae({name:"WippyHostRouterLink",props:{to:{type:String,required:!0}},setup(e,{slots:t}){return()=>qe("a",{href:e.to,onClick:n=>{n.defaultPrevented||n.button!==0||n.metaKey||n.altKey||n.ctrlKey||n.shiftKey||(n.preventDefault(),St.navigate(e.to))}},t.default?.())}});Ae({name:"WippyAutoRouterLink",props:{to:{type:[String,Object],required:!0},replace:{type:Boolean,default:!1},activeClass:{type:String,default:void 0},exactActiveClass:{type:String,default:void 0},ariaCurrentValue:{type:String,default:"page"},externalTarget:{type:String,default:"_blank"}},setup(e,{slots:t}){const n=On();return()=>{const o=n.resolve(e.to),r=St.classifyLink(o.href);if(r.kind==="host-nav")return qe("a",{href:o.href,onClick:i=>{i.defaultPrevented||i.button===0&&(i.metaKey||i.altKey||i.ctrlKey||i.shiftKey||(i.preventDefault(),St.navigate(r.normalizedPath??r.href)))},"aria-current":e.ariaCurrentValue},t.default?.());if(r.kind==="external"){const i=e.externalTarget==="_blank";return qe("a",{href:o.href,target:e.externalTarget||void 0,rel:i?"noopener noreferrer":void 0},t.default?.())}return r.kind==="ignore"?qe("a",{href:o.href||"#",onClick:i=>i.preventDefault()},t.default?.()):qe(co,{to:e.to,replace:e.replace,activeClass:e.activeClass,exactActiveClass:e.exactActiveClass,ariaCurrentValue:e.ariaCurrentValue},t.default?{default:i=>t.default?.(i)}:void 0)}}});const ui=[{path:"/",name:"dashboard",component:()=>A(()=>import("./assets/dashboard-BoC60m2r.js"),__vite__mapDeps([0,1,2,3,4,5,6,7,8]),import.meta.url)},{path:"/dataflows",name:"workflow",component:()=>A(()=>import("./assets/workflow-BnPrisCC.js"),__vite__mapDeps([9,3]),import.meta.url)},{path:"/sessions",name:"sessions",component:()=>A(()=>import("./assets/sessions-BrMpENKd.js"),__vite__mapDeps([10,11]),import.meta.url)},{path:"/session/:id",name:"session-detail",component:()=>A(()=>import("./assets/session-detail-bdehc96W.js"),__vite__mapDeps([12,1,13,14,15]),import.meta.url)},{path:"/agents",name:"agents",component:()=>A(()=>import("./assets/agents-CXZKW6R6.js"),__vite__mapDeps([16,1,8,17,14,15,11]),import.meta.url)},{path:"/models",name:"models",component:()=>A(()=>import("./assets/models-DagISYWm.js"),__vite__mapDeps([18,1,8,17,14,15,11]),import.meta.url)},{path:"/tools",name:"tools",component:()=>A(()=>import("./assets/tools-page-BnGcuW3d.js"),__vite__mapDeps([19,1,8,17,14,15,11]),import.meta.url)},{path:"/traits",name:"traits",component:()=>A(()=>import("./assets/traits-CqK6Tvxw.js"),__vite__mapDeps([20,1,8,17,14,15,11]),import.meta.url)},{path:"/endpoints",name:"endpoints",component:()=>A(()=>import("./assets/endpoints-BP0DLIfc.js"),__vite__mapDeps([21,1,17,14,15,11]),import.meta.url)},{path:"/policies",name:"policies",component:()=>A(()=>import("./assets/policies-A8uyu8Ny.js"),__vite__mapDeps([22,1,8,17,14,15,11]),import.meta.url)},{path:"/structure",name:"structure",component:()=>A(()=>import("./assets/structure-B1RAr-WV.js"),__vite__mapDeps([23,8]),import.meta.url)},{path:"/dataflow/:id",name:"dataflow-detail",component:()=>A(()=>import("./assets/dataflow-detail-BKm98Fuh.js"),__vite__mapDeps([24,1,3,13,15]),import.meta.url)},{path:"/plugin/:id",name:"plugin",component:()=>A(()=>import("./assets/plugin-page-DbeqvIim.js"),__vite__mapDeps([25,26]),import.meta.url)},{path:"/logs",name:"logs",component:()=>A(()=>import("./assets/logger-CJ4vPYnn.js"),__vite__mapDeps([27,6,11]),import.meta.url)},{path:"/system",name:"system",component:()=>A(()=>import("./assets/system-Ba_7tip8.js"),__vite__mapDeps([28,2,11]),import.meta.url)},{path:"/tests",name:"tests",component:()=>A(()=>import("./assets/tests-C21pmcDl.js"),__vite__mapDeps([29,8]),import.meta.url)},{path:"/settings",name:"settings",component:()=>A(()=>import("./assets/settings-86u394KL.js"),__vite__mapDeps([30,11]),import.meta.url)},{path:"/settings/environment",name:"settings-environment",component:()=>A(()=>import("./assets/settings-environment-0WJtHASA.js"),__vite__mapDeps([31,11]),import.meta.url)},{path:"/settings/registry",name:"settings-registry",component:()=>A(()=>import("./assets/settings-registry-DF_Q3U4N.js"),__vite__mapDeps([32,11]),import.meta.url)},{path:"/settings/hub",name:"settings-hub",component:()=>A(()=>import("./assets/settings-hub-B-3IO59d.js"),__vite__mapDeps([33,1,34,11]),import.meta.url)},{path:"/settings/hub/:org/:name",name:"settings-hub-module",component:()=>A(()=>import("./assets/settings-hub-module-a6OXDRnn.js"),__vite__mapDeps([35,1,34]),import.meta.url)},{path:"/knowledge",name:"knowledge",component:()=>A(()=>import("./assets/knowledge-B7f2toOe.js"),__vite__mapDeps([36,7,13]),import.meta.url)},{path:"/mcp",name:"mcp",component:()=>A(()=>import("./assets/mcp-xa6ZkHDG.js"),[],import.meta.url)},{path:"/components",name:"components",component:()=>A(()=>import("./assets/components-C4F7M12i.js"),__vite__mapDeps([37,13,15]),import.meta.url)},{path:"/tasks",name:"tasks",component:()=>A(()=>import("./assets/tasks-C61-GdIs.js"),__vite__mapDeps([38,4]),import.meta.url)},{path:"/tasks/:id",name:"task-detail",component:()=>A(()=>import("./assets/task-detail-CQKVHbFl.js"),__vite__mapDeps([39,1,4,13]),import.meta.url)},{path:"/changes",name:"changes",component:()=>A(()=>import("./assets/changes-DuD77g77.js"),__vite__mapDeps([40,1,5,26]),import.meta.url)},{path:"/changes/:id",name:"changes-detail",component:()=>A(()=>import("./assets/changes-DuD77g77.js"),__vite__mapDeps([40,1,5,26]),import.meta.url)},{path:"/audit",name:"audit",component:()=>A(()=>import("./assets/audit-CZqtKQmG.js"),[],import.meta.url)},{path:"/:pathMatch(.*)*",name:"not-found",redirect:"/"}];function di(e,t,n){return li(ui,{initialPath:n,host:e,on:t})}async function ci(){const e=await window.$W.config(),t=await window.$W.host(),n=await window.$W.api(),o=await window.$W.instance();n.interceptors.response.use(u=>u,u=>(u?.response?.status===401&&t.handleError("auth-expired",{url:u?.config?.url,method:u?.config?.method,message:u?.message}),Promise.reject(u)));let r=null;try{r=await window.$W.on()}catch{}const i=e.context?.route||"/",s=e.theming?.global?.icons??e.theming?.global?.iconSets?.custom;s&&Gn({prefix:"custom",icons:s});const l=io(ai);l.use(Yn()),l.use(gr),l.provide(Wn,t),l.provide(qn,n),l.provide(Hn,o),l.provide(ya,e),r&&l.provide(_a,r);const a=di(t,o.on,i);return l.use(a),l}async function pi(e="#app"){const t=await ci();return t.mount(e),t}pi();export{Li as A,Ti as B,I as C,Kt as D,Fe as E,Fn as _,zn as a,hi as b,Ei as c,wa as d,Di as e,Ii as f,Pi as g,Ni as h,ji as i,Sa as j,_i as k,yi as l,A as m,_t as n,Kn as o,Si as p,ki as q,wi as r,ut as s,wn as t,ka as u,$i as v,Oi as w,xi as x,Ci as y,Ai as z};
