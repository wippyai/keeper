const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./assets/dashboard-CSK4-BTI.js","./assets/index-BT_m-wrW.js","./assets/pm-Dj_62FpQ.js","./assets/dataflows-Dr2Ef8bh.js","./assets/tasks-CxgCqZXy.js","./assets/changelog-kS_NZw1C.js","./assets/logger-Cq9hvQPy.js","./assets/knowledge-iW30SVUZ.js","./assets/utils-CSjTgnrH.js","./assets/workflow-BnPrisCC.js","./assets/sessions-BrMpENKd.js","./assets/PageHeader.vue_vue_type_script_setup_true_lang-x-0LZxLa.js","./assets/session-detail-CDshxVJR.js","./assets/MarkdownContent-DyBNkW15.js","./assets/DetailPanel.vue_vue_type_script_setup_true_lang-B115sO7W.js","./assets/JsonBlock.vue_vue_type_script_setup_true_lang-D4lkhHol.js","./assets/agents-Pl02yESY.js","./assets/EntryDetailPanel-Dfl-NBLe.js","./assets/models-B3DPFv9Z.js","./assets/tools-page-D8Jt7la8.js","./assets/traits-BW2MPbA7.js","./assets/endpoints-B9BCTqnt.js","./assets/policies-BgLUSNmY.js","./assets/structure-BoeDRm0U.js","./assets/dataflow-detail-CBigbUg1.js","./assets/plugin-page-78CA4jh7.js","./assets/PluginHost-DUK2xtKt.js","./assets/logger-CJ4vPYnn.js","./assets/activity-BTPuvvNP.js","./assets/system-Ba_7tip8.js","./assets/tests-C21pmcDl.js","./assets/settings-86u394KL.js","./assets/settings-environment-DV741d7r.js","./assets/settings-registry-CUu_UwsG.js","./assets/settings-hub-y1XekLoM.js","./assets/RequirementValueInput-CzlAplA9.js","./assets/settings-hub-module-CFfP-n46.js","./assets/knowledge-B7f2toOe.js","./assets/components-C4F7M12i.js","./assets/tasks-C61-GdIs.js","./assets/task-detail-_SqHbZ-7.js","./assets/changes-CQL3LW9V.js"])))=>i.map(i=>d[i]);
import{Icon as K,addCollection as ao}from"@iconify/vue";import{createPinia as io}from"pinia";import{ref as M,readonly as so,getCurrentInstance as nn,onMounted as jn,nextTick as lo,watch as De,reactive as uo,useId as co,mergeProps as J,openBlock as T,createElementBlock as L,createElementVNode as V,renderSlot as Ke,createTextVNode as Ze,toDisplayString as X,resolveComponent as Ut,resolveDirective as po,withDirectives as mo,createBlock as Me,resolveDynamicComponent as fo,withCtx as Ve,createCommentVNode as F,normalizeClass as xe,inject as Gt,defineComponent as Le,createVNode as N,unref as C,Fragment as Je,renderList as Xe,Teleport as bo,withModifiers as vo,withKeys as on,normalizeStyle as zt,computed as H,onUnmounted as go,h as Fe,createApp as ho}from"vue";import{useRouter as Nn,useRoute as yo,createMemoryHistory as _o,createRouter as So,RouterLink as ko}from"vue-router";import{host as $t,on as wo,setLocalRouter as $o}from"@wippy-fe/proxy";(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))o(r);new MutationObserver(r=>{for(const i of r)if(i.type==="childList")for(const s of i.addedNodes)s.tagName==="LINK"&&s.rel==="modulepreload"&&o(s)}).observe(document,{childList:!0,subtree:!0});function n(r){const i={};return r.integrity&&(i.integrity=r.integrity),r.referrerPolicy&&(i.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?i.credentials="include":r.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function o(r){if(r.ep)return;r.ep=!0;const i=n(r);fetch(r.href,i)}})();var Po=Object.defineProperty,rn=Object.getOwnPropertySymbols,Oo=Object.prototype.hasOwnProperty,To=Object.prototype.propertyIsEnumerable,an=(e,t,n)=>t in e?Po(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,xo=(e,t)=>{for(var n in t||(t={}))Oo.call(t,n)&&an(e,n,t[n]);if(rn)for(var n of rn(t))To.call(t,n)&&an(e,n,t[n]);return e};function Ee(e){return e==null||e===""||Array.isArray(e)&&e.length===0||!(e instanceof Date)&&typeof e=="object"&&Object.keys(e).length===0}function Yt(e){return typeof e=="function"&&"call"in e&&"apply"in e}function I(e){return!Ee(e)}function ge(e,t=!0){return e instanceof Object&&e.constructor===Object&&(t||Object.keys(e).length!==0)}function In(e={},t={}){let n=xo({},e);return Object.keys(t).forEach(o=>{let r=o;ge(t[r])&&r in e&&ge(e[r])?n[r]=In(e[r],t[r]):n[r]=t[r]}),n}function Co(...e){return e.reduce((t,n,o)=>o===0?n:In(t,n),{})}function se(e,...t){return Yt(e)?e(...t):e}function ee(e,t=!0){return typeof e=="string"&&(t||e!=="")}function ve(e){return ee(e)?e.replace(/(-|_)/g,"").toLowerCase():e}function Qt(e,t="",n={}){let o=ve(t).split("."),r=o.shift();if(r){if(ge(e)){let i=Object.keys(e).find(s=>ve(s)===r)||"";return Qt(se(e[i],n),o.join("."),n)}return}return se(e,n)}function Dn(e,t=!0){return Array.isArray(e)&&(t||e.length!==0)}function Ao(e){return I(e)&&!isNaN(e)}function Ce(e,t){if(t){let n=t.test(e);return t.lastIndex=0,n}return!1}function Lo(...e){return Co(...e)}function Ye(e){return e&&e.replace(/\/\*(?:(?!\*\/)[\s\S])*\*\/|[\r\n\t]+/g,"").replace(/ {2,}/g," ").replace(/ ([{:}]) /g,"$1").replace(/([;,]) /g,"$1").replace(/ !/g,"!").replace(/: /g,":").trim()}function Eo(e){return ee(e,!1)?e[0].toUpperCase()+e.slice(1):e}function Rn(e){return ee(e)?e.replace(/(_)/g,"-").replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase():e}function Mn(){let e=new Map;return{on(t,n){let o=e.get(t);return o?o.push(n):o=[n],e.set(t,o),this},off(t,n){let o=e.get(t);return o&&o.splice(o.indexOf(n)>>>0,1),this},emit(t,n){let o=e.get(t);o&&o.forEach(r=>{r(n)})},clear(){e.clear()}}}function Qe(...e){if(e){let t=[];for(let n=0;n<e.length;n++){let o=e[n];if(!o)continue;let r=typeof o;if(r==="string"||r==="number")t.push(o);else if(r==="object"){let i=Array.isArray(o)?[Qe(...o)]:Object.entries(o).map(([s,l])=>l?s:void 0);t=i.length?t.concat(i.filter(s=>!!s)):t}}return t.join(" ").trim()}}function jo(e,t){return e?e.classList?e.classList.contains(t):new RegExp("(^| )"+t+"( |$)","gi").test(e.className):!1}function No(e,t){if(e&&t){let n=o=>{jo(e,o)||(e.classList?e.classList.add(o):e.className+=" "+o)};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Dt(e,t){if(e&&t){let n=o=>{e.classList?e.classList.remove(o):e.className=e.className.replace(new RegExp("(^|\\b)"+o.split(" ").join("|")+"(\\b|$)","gi")," ")};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function sn(e){return e?Math.abs(e.scrollLeft):0}function Io(e,t){return e instanceof HTMLElement?e.offsetWidth:0}function Do(e){if(e){let t=e.parentNode;return t&&t instanceof ShadowRoot&&t.host&&(t=t.host),t}return null}function Ro(e){return!!(e!==null&&typeof e<"u"&&e.nodeName&&Do(e))}function pt(e){return typeof Element<"u"?e instanceof Element:e!==null&&typeof e=="object"&&e.nodeType===1&&typeof e.nodeName=="string"}function Pt(e,t={}){if(pt(e)){let n=(o,r)=>{var i,s;let l=(i=e?.$attrs)!=null&&i[o]?[(s=e?.$attrs)==null?void 0:s[o]]:[];return[r].flat().reduce((a,u)=>{if(u!=null){let d=typeof u;if(d==="string"||d==="number")a.push(u);else if(d==="object"){let c=Array.isArray(u)?n(o,u):Object.entries(u).map(([p,m])=>o==="style"&&(m||m===0)?`${p.replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()}:${m}`:m?p:void 0);a=c.length?a.concat(c.filter(p=>!!p)):a}}return a},l)};Object.entries(t).forEach(([o,r])=>{if(r!=null){let i=o.match(/^on(.+)/);i?e.addEventListener(i[1].toLowerCase(),r):o==="p-bind"||o==="pBind"?Pt(e,r):(r=o==="class"?[...new Set(n("class",r))].join(" ").trim():o==="style"?n("style",r).join(";").trim():r,(e.$attrs=e.$attrs||{})&&(e.$attrs[o]=r),e.setAttribute(o,r))}})}}function Mo(e,t={},...n){{let o=document.createElement(e);return Pt(o,t),o.append(...n),o}}function Vo(e,t){return pt(e)?e.matches(t)?e:e.querySelector(t):null}function Bo(e,t){if(pt(e)){let n=e.getAttribute(t);return isNaN(n)?n==="true"||n==="false"?n==="true":n:+n}}function ln(e){if(e){let t=e.offsetHeight,n=getComputedStyle(e);return t-=parseFloat(n.paddingTop)+parseFloat(n.paddingBottom)+parseFloat(n.borderTopWidth)+parseFloat(n.borderBottomWidth),t}return 0}function Uo(e){if(e){let t=e.getBoundingClientRect();return{top:t.top+(window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0),left:t.left+(window.pageXOffset||sn(document.documentElement)||sn(document.body)||0)}}return{top:"auto",left:"auto"}}function zo(e,t){return e?e.offsetHeight:0}function un(e){if(e){let t=e.offsetWidth,n=getComputedStyle(e);return t-=parseFloat(n.paddingLeft)+parseFloat(n.paddingRight)+parseFloat(n.borderLeftWidth)+parseFloat(n.borderRightWidth),t}return 0}function Wo(){return!!(typeof window<"u"&&window.document&&window.document.createElement)}function qo(e,t="",n){pt(e)&&n!==null&&n!==void 0&&e.setAttribute(t,n)}var ht={};function Ho(e="pui_id_"){return Object.hasOwn(ht,e)||(ht[e]=0),ht[e]++,`${e}${ht[e]}`}var Ko=Object.defineProperty,Fo=Object.defineProperties,Go=Object.getOwnPropertyDescriptors,Ot=Object.getOwnPropertySymbols,Vn=Object.prototype.hasOwnProperty,Bn=Object.prototype.propertyIsEnumerable,dn=(e,t,n)=>t in e?Ko(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,fe=(e,t)=>{for(var n in t||(t={}))Vn.call(t,n)&&dn(e,n,t[n]);if(Ot)for(var n of Ot(t))Bn.call(t,n)&&dn(e,n,t[n]);return e},Rt=(e,t)=>Fo(e,Go(t)),ye=(e,t)=>{var n={};for(var o in e)Vn.call(e,o)&&t.indexOf(o)<0&&(n[o]=e[o]);if(e!=null&&Ot)for(var o of Ot(e))t.indexOf(o)<0&&Bn.call(e,o)&&(n[o]=e[o]);return n},Yo=Mn(),z=Yo,et=/{([^}]*)}/g,Un=/(\d+\s+[\+\-\*\/]\s+\d+)/g,zn=/var\([^)]+\)/g;function cn(e){return ee(e)?e.replace(/[A-Z]/g,(t,n)=>n===0?t:"."+t.toLowerCase()).toLowerCase():e}function Qo(e){return ge(e)&&e.hasOwnProperty("$value")&&e.hasOwnProperty("$type")?e.$value:e}function Zo(e){return e.replaceAll(/ /g,"").replace(/[^\w]/g,"-")}function Wt(e="",t=""){return Zo(`${ee(e,!1)&&ee(t,!1)?`${e}-`:e}${t}`)}function Wn(e="",t=""){return`--${Wt(e,t)}`}function Jo(e=""){let t=(e.match(/{/g)||[]).length,n=(e.match(/}/g)||[]).length;return(t+n)%2!==0}function qn(e,t="",n="",o=[],r){if(ee(e)){let i=e.trim();if(Jo(i))return;if(Ce(i,et)){let s=i.replaceAll(et,l=>{let a=l.replace(/{|}/g,"").split(".").filter(u=>!o.some(d=>Ce(u,d)));return`var(${Wn(n,Rn(a.join("-")))}${I(r)?`, ${r}`:""})`});return Ce(s.replace(zn,"0"),Un)?`calc(${s})`:s}return i}else if(Ao(e))return e}function Xo(e,t,n){ee(t,!1)&&e.push(`${t}:${n};`)}function Ie(e,t){return e?`${e}{${t}}`:""}function Hn(e,t){if(e.indexOf("dt(")===-1)return e;function n(s,l){let a=[],u=0,d="",c=null,p=0;for(;u<=s.length;){let m=s[u];if((m==='"'||m==="'"||m==="`")&&s[u-1]!=="\\"&&(c=c===m?null:m),!c&&(m==="("&&p++,m===")"&&p--,(m===","||u===s.length)&&p===0)){let b=d.trim();b.startsWith("dt(")?a.push(Hn(b,l)):a.push(o(b)),d="",u++;continue}m!==void 0&&(d+=m),u++}return a}function o(s){let l=s[0];if((l==='"'||l==="'"||l==="`")&&s[s.length-1]===l)return s.slice(1,-1);let a=Number(s);return isNaN(a)?s:a}let r=[],i=[];for(let s=0;s<e.length;s++)if(e[s]==="d"&&e.slice(s,s+3)==="dt(")i.push(s),s+=2;else if(e[s]===")"&&i.length>0){let l=i.pop();i.length===0&&r.push([l,s])}if(!r.length)return e;for(let s=r.length-1;s>=0;s--){let[l,a]=r[s],u=e.slice(l+3,a),d=n(u,t),c=t(...d);e=e.slice(0,l)+c+e.slice(a+1)}return e}var Ae=(...e)=>er(j.getTheme(),...e),er=(e={},t,n,o)=>{if(t){let{variable:r,options:i}=j.defaults||{},{prefix:s,transform:l}=e?.options||i||{},a=Ce(t,et)?t:`{${t}}`;return o==="value"||Ee(o)&&l==="strict"?j.getTokenValue(t):qn(a,void 0,s,[r.excludedKeyRegex],n)}return""};function yt(e,...t){if(e instanceof Array){let n=e.reduce((o,r,i)=>{var s;return o+r+((s=se(t[i],{dt:Ae}))!=null?s:"")},"");return Hn(n,Ae)}return se(e,{dt:Ae})}function tr(e,t={}){let n=j.defaults.variable,{prefix:o=n.prefix,selector:r=n.selector,excludedKeyRegex:i=n.excludedKeyRegex}=t,s=[],l=[],a=[{node:e,path:o}];for(;a.length;){let{node:d,path:c}=a.pop();for(let p in d){let m=d[p],b=Qo(m),_=Ce(p,i)?Wt(c):Wt(c,Rn(p));if(ge(b))a.push({node:b,path:_});else{let h=Wn(_),S=qn(b,_,o,[i]);Xo(l,h,S);let O=_;o&&O.startsWith(o+"-")&&(O=O.slice(o.length+1)),s.push(O.replace(/-/g,"."))}}}let u=l.join("");return{value:l,tokens:s,declarations:u,css:Ie(r,u)}}var me={regex:{rules:{class:{pattern:/^\.([a-zA-Z][\w-]*)$/,resolve(e){return{type:"class",selector:e,matched:this.pattern.test(e.trim())}}},attr:{pattern:/^\[(.*)\]$/,resolve(e){return{type:"attr",selector:`:root${e},:host${e}`,matched:this.pattern.test(e.trim())}}},media:{pattern:/^@media (.*)$/,resolve(e){return{type:"media",selector:e,matched:this.pattern.test(e.trim())}}},system:{pattern:/^system$/,resolve(e){return{type:"system",selector:"@media (prefers-color-scheme: dark)",matched:this.pattern.test(e.trim())}}},custom:{resolve(e){return{type:"custom",selector:e,matched:!0}}}},resolve(e){let t=Object.keys(this.rules).filter(n=>n!=="custom").map(n=>this.rules[n]);return[e].flat().map(n=>{var o;return(o=t.map(r=>r.resolve(n)).find(r=>r.matched))!=null?o:this.rules.custom.resolve(n)})}},_toVariables(e,t){return tr(e,{prefix:t?.prefix})},getCommon({name:e="",theme:t={},params:n,set:o,defaults:r}){var i,s,l,a,u,d,c;let{preset:p,options:m}=t,b,_,h,S,O,E,v;if(I(p)&&m.transform!=="strict"){let{primitive:k,semantic:B,extend:q}=p,ue=B||{},{colorScheme:de}=ue,ce=ye(ue,["colorScheme"]),G=q||{},{colorScheme:te}=G,ne=ye(G,["colorScheme"]),Y=de||{},{dark:oe}=Y,re=ye(Y,["dark"]),he=te||{},{dark:_e}=he,Se=ye(he,["dark"]),pe=I(k)?this._toVariables({primitive:k},m):{},le=I(ce)?this._toVariables({semantic:ce},m):{},R=I(re)?this._toVariables({light:re},m):{},je=I(oe)?this._toVariables({dark:oe},m):{},ke=I(ne)?this._toVariables({semantic:ne},m):{},mt=I(Se)?this._toVariables({light:Se},m):{},ft=I(_e)?this._toVariables({dark:_e},m):{},[xt,bt]=[(i=pe.declarations)!=null?i:"",pe.tokens],[Ne,Ct]=[(s=le.declarations)!=null?s:"",le.tokens||[]],[Oe,At]=[(l=R.declarations)!=null?l:"",R.tokens||[]],[vt,Lt]=[(a=je.declarations)!=null?a:"",je.tokens||[]],[Et,we]=[(u=ke.declarations)!=null?u:"",ke.tokens||[]],[Te,ae]=[(d=mt.declarations)!=null?d:"",mt.tokens||[]],[ze,We]=[(c=ft.declarations)!=null?c:"",ft.tokens||[]];b=this.transformCSS(e,xt,"light","variable",m,o,r),_=bt;let jt=this.transformCSS(e,`${Ne}${Oe}`,"light","variable",m,o,r),gt=this.transformCSS(e,`${vt}`,"dark","variable",m,o,r);h=`${jt}${gt}`,S=[...new Set([...Ct,...At,...Lt])];let Nt=this.transformCSS(e,`${Et}${Te}color-scheme:light`,"light","variable",m,o,r),It=this.transformCSS(e,`${ze}color-scheme:dark`,"dark","variable",m,o,r);O=`${Nt}${It}`,E=[...new Set([...we,...ae,...We])],v=se(p.css,{dt:Ae})}return{primitive:{css:b,tokens:_},semantic:{css:h,tokens:S},global:{css:O,tokens:E},style:v}},getPreset({name:e="",preset:t={},options:n,params:o,set:r,defaults:i,selector:s}){var l,a,u;let d,c,p;if(I(t)&&n.transform!=="strict"){let m=e.replace("-directive",""),b=t,{colorScheme:_,extend:h,css:S}=b,O=ye(b,["colorScheme","extend","css"]),E=h||{},{colorScheme:v}=E,k=ye(E,["colorScheme"]),B=_||{},{dark:q}=B,ue=ye(B,["dark"]),de=v||{},{dark:ce}=de,G=ye(de,["dark"]),te=I(O)?this._toVariables({[m]:fe(fe({},O),k)},n):{},ne=I(ue)?this._toVariables({[m]:fe(fe({},ue),G)},n):{},Y=I(q)?this._toVariables({[m]:fe(fe({},q),ce)},n):{},[oe,re]=[(l=te.declarations)!=null?l:"",te.tokens||[]],[he,_e]=[(a=ne.declarations)!=null?a:"",ne.tokens||[]],[Se,pe]=[(u=Y.declarations)!=null?u:"",Y.tokens||[]],le=this.transformCSS(m,`${oe}${he}`,"light","variable",n,r,i,s),R=this.transformCSS(m,Se,"dark","variable",n,r,i,s);d=`${le}${R}`,c=[...new Set([...re,..._e,...pe])],p=se(S,{dt:Ae})}return{css:d,tokens:c,style:p}},getPresetC({name:e="",theme:t={},params:n,set:o,defaults:r}){var i;let{preset:s,options:l}=t,a=(i=s?.components)==null?void 0:i[e];return this.getPreset({name:e,preset:a,options:l,params:n,set:o,defaults:r})},getPresetD({name:e="",theme:t={},params:n,set:o,defaults:r}){var i,s;let l=e.replace("-directive",""),{preset:a,options:u}=t,d=((i=a?.components)==null?void 0:i[l])||((s=a?.directives)==null?void 0:s[l]);return this.getPreset({name:l,preset:d,options:u,params:n,set:o,defaults:r})},applyDarkColorScheme(e){return!(e.darkModeSelector==="none"||e.darkModeSelector===!1)},getColorSchemeOption(e,t){var n;return this.applyDarkColorScheme(e)?this.regex.resolve(e.darkModeSelector===!0?t.options.darkModeSelector:(n=e.darkModeSelector)!=null?n:t.options.darkModeSelector):[]},getLayerOrder(e,t={},n,o){let{cssLayer:r}=t;return r?`@layer ${se(r.order||r.name||"primeui",n)}`:""},getCommonStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:i}){let s=this.getCommon({name:e,theme:t,params:n,set:r,defaults:i}),l=Object.entries(o).reduce((a,[u,d])=>a.push(`${u}="${d}"`)&&a,[]).join(" ");return Object.entries(s||{}).reduce((a,[u,d])=>{if(ge(d)&&Object.hasOwn(d,"css")){let c=Ye(d.css),p=`${u}-variables`;a.push(`<style type="text/css" data-primevue-style-id="${p}" ${l}>${c}</style>`)}return a},[]).join("")},getStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:i}){var s;let l={name:e,theme:t,params:n,set:r,defaults:i},a=(s=e.includes("-directive")?this.getPresetD(l):this.getPresetC(l))==null?void 0:s.css,u=Object.entries(o).reduce((d,[c,p])=>d.push(`${c}="${p}"`)&&d,[]).join(" ");return a?`<style type="text/css" data-primevue-style-id="${e}-variables" ${u}>${Ye(a)}</style>`:""},createTokens(e={},t,n="",o="",r={}){let i=function(l,a={},u=[]){if(u.includes(this.path))return console.warn(`Circular reference detected at ${this.path}`),{colorScheme:l,path:this.path,paths:a,value:void 0};u.push(this.path),a.name=this.path,a.binding||(a.binding={});let d=this.value;if(typeof this.value=="string"&&et.test(this.value)){let c=this.value.trim().replace(et,p=>{var m;let b=p.slice(1,-1),_=this.tokens[b];if(!_)return console.warn(`Token not found for path: ${b}`),"__UNRESOLVED__";let h=_.computed(l,a,u);return Array.isArray(h)&&h.length===2?`light-dark(${h[0].value},${h[1].value})`:(m=h?.value)!=null?m:"__UNRESOLVED__"});d=Un.test(c.replace(zn,"0"))?`calc(${c})`:c}return Ee(a.binding)&&delete a.binding,u.pop(),{colorScheme:l,path:this.path,paths:a,value:d.includes("__UNRESOLVED__")?void 0:d}},s=(l,a,u)=>{Object.entries(l).forEach(([d,c])=>{let p=Ce(d,t.variable.excludedKeyRegex)?a:a?`${a}.${cn(d)}`:cn(d),m=u?`${u}.${d}`:d;ge(c)?s(c,p,m):(r[p]||(r[p]={paths:[],computed:(b,_={},h=[])=>{if(r[p].paths.length===1)return r[p].paths[0].computed(r[p].paths[0].scheme,_.binding,h);if(b&&b!=="none")for(let S=0;S<r[p].paths.length;S++){let O=r[p].paths[S];if(O.scheme===b)return O.computed(b,_.binding,h)}return r[p].paths.map(S=>S.computed(S.scheme,_[S.scheme],h))}}),r[p].paths.push({path:m,value:c,scheme:m.includes("colorScheme.light")?"light":m.includes("colorScheme.dark")?"dark":"none",computed:i,tokens:r}))})};return s(e,n,o),r},getTokenValue(e,t,n){var o;let r=(l=>l.split(".").filter(a=>!Ce(a.toLowerCase(),n.variable.excludedKeyRegex)).join("."))(t),i=t.includes("colorScheme.light")?"light":t.includes("colorScheme.dark")?"dark":void 0,s=[(o=e[r])==null?void 0:o.computed(i)].flat().filter(l=>l);return s.length===1?s[0].value:s.reduce((l={},a)=>{let u=a,{colorScheme:d}=u,c=ye(u,["colorScheme"]);return l[d]=c,l},void 0)},getSelectorRule(e,t,n,o){return n==="class"||n==="attr"?Ie(I(t)?`${e}${t},${e} ${t}`:e,o):Ie(e,Ie(t??":root,:host",o))},transformCSS(e,t,n,o,r={},i,s,l){if(I(t)){let{cssLayer:a}=r;if(o!=="style"){let u=this.getColorSchemeOption(r,s);t=n==="dark"?u.reduce((d,{type:c,selector:p})=>(I(p)&&(d+=p.includes("[CSS]")?p.replace("[CSS]",t):this.getSelectorRule(p,l,c,t)),d),""):Ie(l??":root,:host",t)}if(a){let u={name:"primeui"};ge(a)&&(u.name=se(a.name,{name:e,type:o})),I(u.name)&&(t=Ie(`@layer ${u.name}`,t),i?.layerNames(u.name))}return t}return""}},j={defaults:{variable:{prefix:"p",selector:":root,:host",excludedKeyRegex:/^(primitive|semantic|components|directives|variables|colorscheme|light|dark|common|root|states|extend|css)$/gi},options:{prefix:"p",darkModeSelector:"system",cssLayer:!1}},_theme:void 0,_layerNames:new Set,_loadedStyleNames:new Set,_loadingStyles:new Set,_tokens:{},update(e={}){let{theme:t}=e;t&&(this._theme=Rt(fe({},t),{options:fe(fe({},this.defaults.options),t.options)}),this._tokens=me.createTokens(this.preset,this.defaults),this.clearLoadedStyleNames())},get theme(){return this._theme},get preset(){var e;return((e=this.theme)==null?void 0:e.preset)||{}},get options(){var e;return((e=this.theme)==null?void 0:e.options)||{}},get tokens(){return this._tokens},getTheme(){return this.theme},setTheme(e){this.update({theme:e}),z.emit("theme:change",e)},getPreset(){return this.preset},setPreset(e){this._theme=Rt(fe({},this.theme),{preset:e}),this._tokens=me.createTokens(e,this.defaults),this.clearLoadedStyleNames(),z.emit("preset:change",e),z.emit("theme:change",this.theme)},getOptions(){return this.options},setOptions(e){this._theme=Rt(fe({},this.theme),{options:e}),this.clearLoadedStyleNames(),z.emit("options:change",e),z.emit("theme:change",this.theme)},getLayerNames(){return[...this._layerNames]},setLayerNames(e){this._layerNames.add(e)},getLoadedStyleNames(){return this._loadedStyleNames},isStyleNameLoaded(e){return this._loadedStyleNames.has(e)},setLoadedStyleName(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames(){this._loadedStyleNames.clear()},getTokenValue(e){return me.getTokenValue(this.tokens,e,this.defaults)},getCommon(e="",t){return me.getCommon({name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getComponent(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPresetC(n)},getDirective(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPresetD(n)},getCustomPreset(e="",t,n,o){let r={name:e,preset:t,options:this.options,selector:n,params:o,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return me.getPreset(r)},getLayerOrderCSS(e=""){return me.getLayerOrder(e,this.options,{names:this.getLayerNames()},this.defaults)},transformCSS(e="",t,n="style",o){return me.transformCSS(e,t,o,n,this.options,{layerNames:this.setLayerNames.bind(this)},this.defaults)},getCommonStyleSheet(e="",t,n={}){return me.getCommonStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getStyleSheet(e,t,n={}){return me.getStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},onStyleMounted(e){this._loadingStyles.add(e)},onStyleUpdated(e){this._loadingStyles.add(e)},onStyleLoaded(e,{name:t}){this._loadingStyles.size&&(this._loadingStyles.delete(t),z.emit(`theme:${t}:load`,e),!this._loadingStyles.size&&z.emit("theme:load"))}},W={STARTS_WITH:"startsWith",CONTAINS:"contains",NOT_CONTAINS:"notContains",ENDS_WITH:"endsWith",EQUALS:"equals",NOT_EQUALS:"notEquals",LESS_THAN:"lt",LESS_THAN_OR_EQUAL_TO:"lte",GREATER_THAN:"gt",GREATER_THAN_OR_EQUAL_TO:"gte",DATE_IS:"dateIs",DATE_IS_NOT:"dateIsNot",DATE_BEFORE:"dateBefore",DATE_AFTER:"dateAfter"},nr=`
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
`;function tt(e){"@babel/helpers - typeof";return tt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},tt(e)}function pn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function mn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?pn(Object(n),!0).forEach(function(o){or(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):pn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function or(e,t,n){return(t=rr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function rr(e){var t=ar(e,"string");return tt(t)=="symbol"?t:t+""}function ar(e,t){if(tt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(tt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function ir(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0;nn()&&nn().components?jn(e):t?e():lo(e)}var sr=0;function lr(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},n=M(!1),o=M(e),r=M(null),i=Wo()?window.document:void 0,s=t.document,l=s===void 0?i:s,a=t.immediate,u=a===void 0?!0:a,d=t.manual,c=d===void 0?!1:d,p=t.name,m=p===void 0?"style_".concat(++sr):p,b=t.id,_=b===void 0?void 0:b,h=t.media,S=h===void 0?void 0:h,O=t.nonce,E=O===void 0?void 0:O,v=t.first,k=v===void 0?!1:v,B=t.onMounted,q=B===void 0?void 0:B,ue=t.onUpdated,de=ue===void 0?void 0:ue,ce=t.onLoad,G=ce===void 0?void 0:ce,te=t.props,ne=te===void 0?{}:te,Y=function(){},oe=function(_e){var Se=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(l){var pe=mn(mn({},ne),Se),le=pe.name||m,R=pe.id||_,je=pe.nonce||E;r.value=l.querySelector('style[data-primevue-style-id="'.concat(le,'"]'))||l.getElementById(R)||l.createElement("style"),r.value.isConnected||(o.value=_e||e,Pt(r.value,{type:"text/css",id:R,media:S,nonce:je}),k?l.head.prepend(r.value):l.head.appendChild(r.value),qo(r.value,"data-primevue-style-id",le),Pt(r.value,pe),r.value.onload=function(ke){return G?.(ke,{name:le})},q?.(le)),!n.value&&(Y=De(o,function(ke){r.value.textContent=ke,de?.(le)},{immediate:!0}),n.value=!0)}},re=function(){!l||!n.value||(Y(),Ro(r.value)&&l.head.removeChild(r.value),n.value=!1,r.value=null)};return u&&!c&&ir(oe),{id:_,name:m,el:r,css:o,unload:re,load:oe,isLoaded:so(n)}}function nt(e){"@babel/helpers - typeof";return nt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},nt(e)}var fn,bn,vn,gn;function hn(e,t){return pr(e)||cr(e,t)||dr(e,t)||ur()}function ur(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function dr(e,t){if(e){if(typeof e=="string")return yn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?yn(e,t):void 0}}function yn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function cr(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t!==0)for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function pr(e){if(Array.isArray(e))return e}function _n(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function Mt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?_n(Object(n),!0).forEach(function(o){mr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):_n(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function mr(e,t,n){return(t=fr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function fr(e){var t=br(e,"string");return nt(t)=="symbol"?t:t+""}function br(e,t){if(nt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(nt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function _t(e,t){return t||(t=e.slice(0)),Object.freeze(Object.defineProperties(e,{raw:{value:Object.freeze(t)}}))}var vr=function(t){var n=t.dt;return`
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
`)},gr={},hr={},D={name:"base",css:vr,style:nr,classes:gr,inlineStyles:hr,load:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:function(i){return i},r=o(yt(fn||(fn=_t(["",""])),t));return I(r)?lr(Ye(r),Mt({name:this.name},n)):{}},loadCSS:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};return this.load(this.css,t)},loadStyle:function(){var t=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"";return this.load(this.style,n,function(){var r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"";return j.transformCSS(n.name||t.name,"".concat(r).concat(yt(bn||(bn=_t(["",""])),o)))})},getCommonTheme:function(t){return j.getCommon(this.name,t)},getComponentTheme:function(t){return j.getComponent(this.name,t)},getDirectiveTheme:function(t){return j.getDirective(this.name,t)},getPresetTheme:function(t,n,o){return j.getCustomPreset(this.name,t,n,o)},getLayerOrderThemeCSS:function(){return j.getLayerOrderCSS(this.name)},getStyleSheet:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(this.css){var o=se(this.css,{dt:Ae})||"",r=Ye(yt(vn||(vn=_t(["","",""])),o,t)),i=Object.entries(n).reduce(function(s,l){var a=hn(l,2),u=a[0],d=a[1];return s.push("".concat(u,'="').concat(d,'"'))&&s},[]).join(" ");return I(r)?'<style type="text/css" data-primevue-style-id="'.concat(this.name,'" ').concat(i,">").concat(r,"</style>"):""}return""},getCommonThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return j.getCommonStyleSheet(this.name,t,n)},getThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=[j.getStyleSheet(this.name,t,n)];if(this.style){var r=this.name==="base"?"global-style":"".concat(this.name,"-style"),i=yt(gn||(gn=_t(["",""])),se(this.style,{dt:Ae})),s=Ye(j.transformCSS(r,i)),l=Object.entries(n).reduce(function(a,u){var d=hn(u,2),c=d[0],p=d[1];return a.push("".concat(c,'="').concat(p,'"'))&&a},[]).join(" ");I(s)&&o.push('<style type="text/css" data-primevue-style-id="'.concat(r,'" ').concat(l,">").concat(s,"</style>"))}return o.join("")},extend:function(t){return Mt(Mt({},this),{},{css:void 0,style:void 0},t)}},Pe=Mn();function ot(e){"@babel/helpers - typeof";return ot=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ot(e)}function Sn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function St(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Sn(Object(n),!0).forEach(function(o){yr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Sn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function yr(e,t,n){return(t=_r(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function _r(e){var t=Sr(e,"string");return ot(t)=="symbol"?t:t+""}function Sr(e,t){if(ot(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ot(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var kr={ripple:!1,inputStyle:null,inputVariant:null,locale:{startsWith:"Starts with",contains:"Contains",notContains:"Not contains",endsWith:"Ends with",equals:"Equals",notEquals:"Not equals",noFilter:"No Filter",lt:"Less than",lte:"Less than or equal to",gt:"Greater than",gte:"Greater than or equal to",dateIs:"Date is",dateIsNot:"Date is not",dateBefore:"Date is before",dateAfter:"Date is after",clear:"Clear",apply:"Apply",matchAll:"Match All",matchAny:"Match Any",addRule:"Add Rule",removeRule:"Remove Rule",accept:"Yes",reject:"No",choose:"Choose",upload:"Upload",cancel:"Cancel",completed:"Completed",pending:"Pending",fileSizeTypes:["B","KB","MB","GB","TB","PB","EB","ZB","YB"],dayNames:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],dayNamesShort:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],dayNamesMin:["Su","Mo","Tu","We","Th","Fr","Sa"],monthNames:["January","February","March","April","May","June","July","August","September","October","November","December"],monthNamesShort:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],chooseYear:"Choose Year",chooseMonth:"Choose Month",chooseDate:"Choose Date",prevDecade:"Previous Decade",nextDecade:"Next Decade",prevYear:"Previous Year",nextYear:"Next Year",prevMonth:"Previous Month",nextMonth:"Next Month",prevHour:"Previous Hour",nextHour:"Next Hour",prevMinute:"Previous Minute",nextMinute:"Next Minute",prevSecond:"Previous Second",nextSecond:"Next Second",am:"am",pm:"pm",today:"Today",weekHeader:"Wk",firstDayOfWeek:0,showMonthAfterYear:!1,dateFormat:"mm/dd/yy",weak:"Weak",medium:"Medium",strong:"Strong",passwordPrompt:"Enter a password",emptyFilterMessage:"No results found",searchMessage:"{0} results are available",selectionMessage:"{0} items selected",emptySelectionMessage:"No selected item",emptySearchMessage:"No results found",fileChosenMessage:"{0} files",noFileChosenMessage:"No file chosen",emptyMessage:"No available options",aria:{trueLabel:"True",falseLabel:"False",nullLabel:"Not Selected",star:"1 star",stars:"{star} stars",selectAll:"All items selected",unselectAll:"All items unselected",close:"Close",previous:"Previous",next:"Next",navigation:"Navigation",scrollTop:"Scroll Top",moveTop:"Move Top",moveUp:"Move Up",moveDown:"Move Down",moveBottom:"Move Bottom",moveToTarget:"Move to Target",moveToSource:"Move to Source",moveAllToTarget:"Move All to Target",moveAllToSource:"Move All to Source",pageLabel:"Page {page}",firstPageLabel:"First Page",lastPageLabel:"Last Page",nextPageLabel:"Next Page",prevPageLabel:"Previous Page",rowsPerPageLabel:"Rows per page",jumpToPageDropdownLabel:"Jump to Page Dropdown",jumpToPageInputLabel:"Jump to Page Input",selectRow:"Row Selected",unselectRow:"Row Unselected",expandRow:"Row Expanded",collapseRow:"Row Collapsed",showFilterMenu:"Show Filter Menu",hideFilterMenu:"Hide Filter Menu",filterOperator:"Filter Operator",filterConstraint:"Filter Constraint",editRow:"Row Edit",saveEdit:"Save Edit",cancelEdit:"Cancel Edit",listView:"List View",gridView:"Grid View",slide:"Slide",slideNumber:"{slideNumber}",zoomImage:"Zoom Image",zoomIn:"Zoom In",zoomOut:"Zoom Out",rotateRight:"Rotate Right",rotateLeft:"Rotate Left",listLabel:"Option List"}},filterMatchModeOptions:{text:[W.STARTS_WITH,W.CONTAINS,W.NOT_CONTAINS,W.ENDS_WITH,W.EQUALS,W.NOT_EQUALS],numeric:[W.EQUALS,W.NOT_EQUALS,W.LESS_THAN,W.LESS_THAN_OR_EQUAL_TO,W.GREATER_THAN,W.GREATER_THAN_OR_EQUAL_TO],date:[W.DATE_IS,W.DATE_IS_NOT,W.DATE_BEFORE,W.DATE_AFTER]},zIndex:{modal:1100,overlay:1e3,menu:1e3,tooltip:1100},theme:void 0,unstyled:!1,pt:void 0,ptOptions:{mergeSections:!0,mergeProps:!1},csp:{nonce:void 0}},wr=Symbol();function $r(e,t){var n={config:uo(t)};return e.config.globalProperties.$primevue=n,e.provide(wr,n),Pr(),Or(e,n),n}var Re=[];function Pr(){z.clear(),Re.forEach(function(e){return e?.()}),Re=[]}function Or(e,t){var n=M(!1),o=function(){var u;if(((u=t.config)===null||u===void 0?void 0:u.theme)!=="none"&&!j.isStyleNameLoaded("common")){var d,c,p=((d=D.getCommonTheme)===null||d===void 0?void 0:d.call(D))||{},m=p.primitive,b=p.semantic,_=p.global,h=p.style,S={nonce:(c=t.config)===null||c===void 0||(c=c.csp)===null||c===void 0?void 0:c.nonce};D.load(m?.css,St({name:"primitive-variables"},S)),D.load(b?.css,St({name:"semantic-variables"},S)),D.load(_?.css,St({name:"global-variables"},S)),D.loadStyle(St({name:"global-style"},S),h),j.setLoadedStyleName("common")}};z.on("theme:change",function(a){n.value||(e.config.globalProperties.$primevue.config.theme=a,n.value=!0)});var r=De(t.config,function(a,u){Pe.emit("config:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0}),i=De(function(){return t.config.ripple},function(a,u){Pe.emit("config:ripple:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0}),s=De(function(){return t.config.theme},function(a,u){n.value||j.setTheme(a),t.config.unstyled||o(),n.value=!1,Pe.emit("config:theme:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!1}),l=De(function(){return t.config.unstyled},function(a,u){!a&&t.config.theme&&o(),Pe.emit("config:unstyled:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0});Re.push(r),Re.push(i),Re.push(s),Re.push(l)}var Tr={install:function(t,n){var o=Lo(kr,n);$r(t,o)}};const xr={install:e=>e.use(Tr,{theme:"none"})};var $e={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(t){return this._loadedStyleNames.has(t)},setLoadedStyleName:function(t){this._loadedStyleNames.add(t)},deleteLoadedStyleName:function(t){this._loadedStyleNames.delete(t)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function Cr(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",t=co();return"".concat(e).concat(t.replace("v-","").replaceAll("-","_"))}var kn=D.extend({name:"common"});function rt(e){"@babel/helpers - typeof";return rt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},rt(e)}function Ar(e){return Gn(e)||Lr(e)||Fn(e)||Kn()}function Lr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function qe(e,t){return Gn(e)||Er(e,t)||Fn(e,t)||Kn()}function Kn(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Fn(e,t){if(e){if(typeof e=="string")return qt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?qt(e,t):void 0}}function qt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Er(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t===0){if(Object(n)!==n)return;a=!1}else for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function Gn(e){if(Array.isArray(e))return e}function wn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function P(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?wn(Object(n),!0).forEach(function(o){Ge(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):wn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ge(e,t,n){return(t=jr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function jr(e){var t=Nr(e,"string");return rt(t)=="symbol"?t:t+""}function Nr(e,t){if(rt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(rt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Zt={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(t){z.off("theme:change",this._loadCoreStyles),t||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(t,n){var o=this;z.off("theme:change",this._themeScopedListener),t?(this._loadScopedThemeStyles(t),this._themeScopedListener=function(){return o._loadScopedThemeStyles(t)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var t,n,o,r,i,s,l,a,u,d,c,p=(t=this.pt)===null||t===void 0?void 0:t._usept,m=p?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,b=p?(o=this.pt)===null||o===void 0||(o=o.value)===null||o===void 0?void 0:o[this.$.type.name]:this.pt;(r=b||m)===null||r===void 0||(r=r.hooks)===null||r===void 0||(i=r.onBeforeCreate)===null||i===void 0||i.call(r);var _=(s=this.$primevueConfig)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s._usept,h=_?(l=this.$primevue)===null||l===void 0||(l=l.config)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l.originalValue:void 0,S=_?(a=this.$primevue)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.pt)===null||a===void 0?void 0:a.value:(u=this.$primevue)===null||u===void 0||(u=u.config)===null||u===void 0?void 0:u.pt;(d=S||h)===null||d===void 0||(d=d[this.$.type.name])===null||d===void 0||(d=d.hooks)===null||d===void 0||(c=d.onBeforeCreate)===null||c===void 0||c.call(d),this.$attrSelector=Cr(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var t;this.rootEl=Vo(pt(this.$el)?this.$el:(t=this.$el)===null||t===void 0?void 0:t.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=P({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(t){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(t)),o=this._useDefaultPT(this._getOptionValue,"hooks.".concat(t));n?.(),o?.()}},_mergeProps:function(t){for(var n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return Yt(t)?t.apply(void 0,o):J.apply(void 0,o)},_load:function(){$e.isStyleNameLoaded("base")||(D.loadCSS(this.$styleOptions),this._loadGlobalStyles(),$e.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var t,n;!$e.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(kn.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),$e.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var t=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);I(t)&&D.load(t,P({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var t,n;if(!(this.isUnstyled||this.$theme==="none")){if(!j.isStyleNameLoaded("common")){var o,r,i=((o=this.$style)===null||o===void 0||(r=o.getCommonTheme)===null||r===void 0?void 0:r.call(o))||{},s=i.primitive,l=i.semantic,a=i.global,u=i.style;D.load(s?.css,P({name:"primitive-variables"},this.$styleOptions)),D.load(l?.css,P({name:"semantic-variables"},this.$styleOptions)),D.load(a?.css,P({name:"global-variables"},this.$styleOptions)),D.loadStyle(P({name:"global-style"},this.$styleOptions),u),j.setLoadedStyleName("common")}if(!j.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var d,c,p,m,b=((d=this.$style)===null||d===void 0||(c=d.getComponentTheme)===null||c===void 0?void 0:c.call(d))||{},_=b.css,h=b.style;(p=this.$style)===null||p===void 0||p.load(_,P({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(m=this.$style)===null||m===void 0||m.loadStyle(P({name:"".concat(this.$style.name,"-style")},this.$styleOptions),h),j.setLoadedStyleName(this.$style.name)}if(!j.isStyleNameLoaded("layer-order")){var S,O,E=(S=this.$style)===null||S===void 0||(O=S.getLayerOrderThemeCSS)===null||O===void 0?void 0:O.call(S);D.load(E,P({name:"layer-order",first:!0},this.$styleOptions)),j.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(t){var n,o,r,i=((n=this.$style)===null||n===void 0||(o=n.getPresetTheme)===null||o===void 0?void 0:o.call(n,t,"[".concat(this.$attrSelector,"]")))||{},s=i.css,l=(r=this.$style)===null||r===void 0?void 0:r.load(s,P({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=l.el},_unloadScopedThemeStyles:function(){var t;(t=this.scopedStyleEl)===null||t===void 0||(t=t.value)===null||t===void 0||t.remove()},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};$e.clearLoadedStyleNames(),z.on("theme:change",t)},_removeThemeListeners:function(){z.off("theme:change",this._loadCoreStyles),z.off("theme:change",this._load),z.off("theme:change",this._themeScopedListener)},_getHostInstance:function(t){return t?this.$options.hostName?t.$.type.name===this.$options.hostName?t:this._getHostInstance(t.$parentInstance):t.$parentInstance:void 0},_getPropValue:function(t){var n;return this[t]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[t])},_getOptionValue:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return Qt(t,n,o)},_getPTValue:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},i=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,s=/./g.test(o)&&!!r[o.split(".")[0]],l=this._getPropValue("ptOptions")||((t=this.$primevueConfig)===null||t===void 0?void 0:t.ptOptions)||{},a=l.mergeSections,u=a===void 0?!0:a,d=l.mergeProps,c=d===void 0?!1:d,p=i?s?this._useGlobalPT(this._getPTClassValue,o,r):this._useDefaultPT(this._getPTClassValue,o,r):void 0,m=s?void 0:this._getPTSelf(n,this._getPTClassValue,o,P(P({},r),{},{global:p||{}})),b=this._getPTDatasets(o);return u||!u&&m?c?this._mergeProps(c,p,m,b):P(P(P({},p),m),b):P(P({},m),b)},_getPTSelf:function(){for(var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return J(this._usePT.apply(this,[this._getPT(t,this.$name)].concat(o)),this._usePT.apply(this,[this.$_attrsPT].concat(o)))},_getPTDatasets:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r="data-pc-",i=o==="root"&&I((t=this.pt)===null||t===void 0?void 0:t["data-pc-section"]);return o!=="transition"&&P(P({},o==="root"&&P(P(Ge({},"".concat(r,"name"),ve(i?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),i&&Ge({},"".concat(r,"extend"),ve(this.$.type.name))),{},Ge({},"".concat(this.$attrSelector),""))),{},Ge({},"".concat(r,"section"),ve(o)))},_getPTClassValue:function(){var t=this._getOptionValue.apply(this,arguments);return ee(t)||Dn(t)?{class:t}:t},_getPT:function(t){var n=this,o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,i=function(l){var a,u=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,d=r?r(l):l,c=ve(o),p=ve(n.$name);return(a=u?c!==p?d?.[c]:void 0:d?.[c])!==null&&a!==void 0?a:d};return t!=null&&t.hasOwnProperty("_usept")?{_usept:t._usept,originalValue:i(t.originalValue),value:i(t.value)}:i(t,!0)},_usePT:function(t,n,o,r){var i=function(_){return n(_,o,r)};if(t!=null&&t.hasOwnProperty("_usept")){var s,l=t._usept||((s=this.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},a=l.mergeSections,u=a===void 0?!0:a,d=l.mergeProps,c=d===void 0?!1:d,p=i(t.originalValue),m=i(t.value);return p===void 0&&m===void 0?void 0:ee(m)?m:ee(p)?p:u||!u&&m?c?this._mergeProps(c,p,m):P(P({},p),m):m}return i(t)},_useGlobalPT:function(t,n,o){return this._usePT(this.globalPT,t,n,o)},_useDefaultPT:function(t,n,o){return this._usePT(this.defaultPT,t,n,o)},ptm:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,t,P(P({},this.$params),n))},ptmi:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=J(this.$_attrsWithoutPT,this.ptm(n,o));return r?.hasOwnProperty("id")&&((t=r.id)!==null&&t!==void 0||(r.id=this.$id)),r},ptmo:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(t,n,P({instance:this},o),!1)},cx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,t,P(P({},this.$params),n))},sx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var r=this._getOptionValue(this.$style.inlineStyles,t,P(P({},this.$params),o)),i=this._getOptionValue(kn.inlineStyles,t,P(P({},this.$params),o));return[i,r]}}},computed:{globalPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return se(o,{instance:n})})},defaultPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return n._getOptionValue(o,n.$name,P({},n.$params))||se(o,P({},n.$params))})},isUnstyled:function(){var t;return this.unstyled!==void 0?this.unstyled:(t=this.$primevueConfig)===null||t===void 0?void 0:t.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var t,n=Object.keys(((t=this.$.vnode)===null||t===void 0?void 0:t.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(o){var r=qe(o,1),i=r[0];return n?.includes(i)}))},$theme:function(){var t;return(t=this.$primevueConfig)===null||t===void 0?void 0:t.theme},$style:function(){return P(P({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var t;return{nonce:(t=this.$primevueConfig)===null||t===void 0||(t=t.csp)===null||t===void 0?void 0:t.nonce}},$primevueConfig:function(){var t;return(t=this.$primevue)===null||t===void 0?void 0:t.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var t=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:t,props:t?.$props,state:t?.$data,attrs:t?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=qe(t,1),o=n[0];return o?.startsWith("pt:")}).reduce(function(t,n){var o=qe(n,2),r=o[0],i=o[1],s=r.split(":"),l=Ar(s),a=qt(l).slice(1);return a?.reduce(function(u,d,c,p){return!u[d]&&(u[d]=c===p.length-1?i:{}),u[d]},t),t},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=qe(t,1),o=n[0];return!(o!=null&&o.startsWith("pt:"))}).reduce(function(t,n){var o=qe(n,2),r=o[0],i=o[1];return t[r]=i,t},{})}}},Ir=`
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
`,Dr=D.extend({name:"baseicon",css:Ir});function at(e){"@babel/helpers - typeof";return at=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},at(e)}function $n(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function Pn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?$n(Object(n),!0).forEach(function(o){Rr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):$n(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Rr(e,t,n){return(t=Mr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Mr(e){var t=Vr(e,"string");return at(t)=="symbol"?t:t+""}function Vr(e,t){if(at(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(at(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Br={name:"BaseIcon",extends:Zt,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:Dr,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var t=Ee(this.label);return Pn(Pn({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:t?void 0:"img","aria-label":t?void 0:this.label,"aria-hidden":t})}}},Yn={name:"SpinnerIcon",extends:Br};function Ur(e){return Hr(e)||qr(e)||Wr(e)||zr()}function zr(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Wr(e,t){if(e){if(typeof e=="string")return Ht(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Ht(e,t):void 0}}function qr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function Hr(e){if(Array.isArray(e))return Ht(e)}function Ht(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Kr(e,t,n,o,r,i){return T(),L("svg",J({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},e.pti()),Ur(t[0]||(t[0]=[V("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}Yn.render=Kr;var Fr=`
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
`,Gr={root:function(t){var n=t.props,o=t.instance;return["p-badge p-component",{"p-badge-circle":I(n.value)&&String(n.value).length===1,"p-badge-dot":Ee(n.value)&&!o.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},Yr=D.extend({name:"badge",style:Fr,classes:Gr}),Qr={name:"BaseBadge",extends:Zt,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:Yr,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function it(e){"@babel/helpers - typeof";return it=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},it(e)}function On(e,t,n){return(t=Zr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Zr(e){var t=Jr(e,"string");return it(t)=="symbol"?t:t+""}function Jr(e,t){if(it(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(it(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Qn={name:"Badge",extends:Qr,inheritAttrs:!1,computed:{dataP:function(){return Qe(On(On({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},Xr=["data-p"];function ea(e,t,n,o,r,i){return T(),L("span",J({class:e.cx("root"),"data-p":i.dataP},e.ptmi("root")),[Ke(e.$slots,"default",{},function(){return[Ze(X(e.value),1)]})],16,Xr)}Qn.render=ea;function st(e){"@babel/helpers - typeof";return st=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},st(e)}function Tn(e,t){return ra(e)||oa(e,t)||na(e,t)||ta()}function ta(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function na(e,t){if(e){if(typeof e=="string")return xn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?xn(e,t):void 0}}function xn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function oa(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t!==0)for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function ra(e){if(Array.isArray(e))return e}function Cn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function x(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Cn(Object(n),!0).forEach(function(o){Kt(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Cn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Kt(e,t,n){return(t=aa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function aa(e){var t=ia(e,"string");return st(t)=="symbol"?t:t+""}function ia(e,t){if(st(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(st(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var w={_getMeta:function(){return[ge(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],se(ge(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(t,n){var o,r,i;return(o=(t==null||(r=t.instance)===null||r===void 0?void 0:r.$primevue)||(n==null||(i=n.ctx)===null||i===void 0||(i=i.appContext)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.globalProperties)===null||i===void 0?void 0:i.$primevue))===null||o===void 0?void 0:o.config},_getOptionValue:Qt,_getPTValue:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},i=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",s=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},l=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,a=function(){var O=w._getOptionValue.apply(w,arguments);return ee(O)||Dn(O)?{class:O}:O},u=((t=o.binding)===null||t===void 0||(t=t.value)===null||t===void 0?void 0:t.ptOptions)||((n=o.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},d=u.mergeSections,c=d===void 0?!0:d,p=u.mergeProps,m=p===void 0?!1:p,b=l?w._useDefaultPT(o,o.defaultPT(),a,i,s):void 0,_=w._usePT(o,w._getPT(r,o.$name),a,i,x(x({},s),{},{global:b||{}})),h=w._getPTDatasets(o,i);return c||!c&&_?m?w._mergeProps(o,m,b,_,h):x(x(x({},b),_),h):x(x({},_),h)},_getPTDatasets:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o="data-pc-";return x(x({},n==="root"&&Kt({},"".concat(o,"name"),ve(t.$name))),{},Kt({},"".concat(o,"section"),ve(n)))},_getPT:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,r=function(s){var l,a=o?o(s):s,u=ve(n);return(l=a?.[u])!==null&&l!==void 0?l:a};return t&&Object.hasOwn(t,"_usept")?{_usept:t._usept,originalValue:r(t.originalValue),value:r(t.value)}:r(t)},_usePT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0,s=function(h){return o(h,r,i)};if(n&&Object.hasOwn(n,"_usept")){var l,a=n._usept||((l=t.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},u=a.mergeSections,d=u===void 0?!0:u,c=a.mergeProps,p=c===void 0?!1:c,m=s(n.originalValue),b=s(n.value);return m===void 0&&b===void 0?void 0:ee(b)?b:ee(m)?m:d||!d&&b?p?w._mergeProps(t,p,m,b):x(x({},m),b):b}return s(n)},_useDefaultPT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0;return w._usePT(t,n,o,r,i)},_loadStyles:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,i=w._getConfig(o,r),s={nonce:i==null||(t=i.csp)===null||t===void 0?void 0:t.nonce};w._loadCoreStyles(n,s),w._loadThemeStyles(n,s),w._loadScopedThemeStyles(n,s),w._removeThemeListeners(n),n.$loadStyles=function(){return w._loadThemeStyles(n,s)},w._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0;if(!$e.isStyleNameLoaded((t=o.$style)===null||t===void 0?void 0:t.name)&&(n=o.$style)!==null&&n!==void 0&&n.name){var i;D.loadCSS(r),(i=o.$style)===null||i===void 0||i.loadCSS(r),$e.setLoadedStyleName(o.$style.name)}},_loadThemeStyles:function(){var t,n,o,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},i=arguments.length>1?arguments[1]:void 0;if(!(r!=null&&r.isUnstyled()||(r==null||(t=r.theme)===null||t===void 0?void 0:t.call(r))==="none")){if(!j.isStyleNameLoaded("common")){var s,l,a=((s=r.$style)===null||s===void 0||(l=s.getCommonTheme)===null||l===void 0?void 0:l.call(s))||{},u=a.primitive,d=a.semantic,c=a.global,p=a.style;D.load(u?.css,x({name:"primitive-variables"},i)),D.load(d?.css,x({name:"semantic-variables"},i)),D.load(c?.css,x({name:"global-variables"},i)),D.loadStyle(x({name:"global-style"},i),p),j.setLoadedStyleName("common")}if(!j.isStyleNameLoaded((n=r.$style)===null||n===void 0?void 0:n.name)&&(o=r.$style)!==null&&o!==void 0&&o.name){var m,b,_,h,S=((m=r.$style)===null||m===void 0||(b=m.getDirectiveTheme)===null||b===void 0?void 0:b.call(m))||{},O=S.css,E=S.style;(_=r.$style)===null||_===void 0||_.load(O,x({name:"".concat(r.$style.name,"-variables")},i)),(h=r.$style)===null||h===void 0||h.loadStyle(x({name:"".concat(r.$style.name,"-style")},i),E),j.setLoadedStyleName(r.$style.name)}if(!j.isStyleNameLoaded("layer-order")){var v,k,B=(v=r.$style)===null||v===void 0||(k=v.getLayerOrderThemeCSS)===null||k===void 0?void 0:k.call(v);D.load(B,x({name:"layer-order",first:!0},i)),j.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=t.preset();if(o&&t.$attrSelector){var r,i,s,l=((r=t.$style)===null||r===void 0||(i=r.getPresetTheme)===null||i===void 0?void 0:i.call(r,o,"[".concat(t.$attrSelector,"]")))||{},a=l.css,u=(s=t.$style)===null||s===void 0?void 0:s.load(a,x({name:"".concat(t.$attrSelector,"-").concat(t.$style.name)},n));t.scopedStyleEl=u.el}},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};$e.clearLoadedStyleNames(),z.on("theme:change",t)},_removeThemeListeners:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};z.off("theme:change",t.$loadStyles),t.$loadStyles=void 0},_hook:function(t,n,o,r,i,s){var l,a,u="on".concat(Eo(n)),d=w._getConfig(r,i),c=o?.$instance,p=w._usePT(c,w._getPT(r==null||(l=r.value)===null||l===void 0?void 0:l.pt,t),w._getOptionValue,"hooks.".concat(u)),m=w._useDefaultPT(c,d==null||(a=d.pt)===null||a===void 0||(a=a.directives)===null||a===void 0?void 0:a[t],w._getOptionValue,"hooks.".concat(u)),b={el:o,binding:r,vnode:i,prevVnode:s};p?.(c,b),m?.(c,b)},_mergeProps:function(){for(var t=arguments.length>1?arguments[1]:void 0,n=arguments.length,o=new Array(n>2?n-2:0),r=2;r<n;r++)o[r-2]=arguments[r];return Yt(t)?t.apply(void 0,o):J.apply(void 0,o)},_extend:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=function(l,a,u,d,c){var p,m,b,_;a._$instances=a._$instances||{};var h=w._getConfig(u,d),S=a._$instances[t]||{},O=Ee(S)?x(x({},n),n?.methods):{};a._$instances[t]=x(x({},S),{},{$name:t,$host:a,$binding:u,$modifiers:u?.modifiers,$value:u?.value,$el:S.$el||a||void 0,$style:x({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:h,$attrSelector:(p=a.$pd)===null||p===void 0||(p=p[t])===null||p===void 0?void 0:p.attrSelector,defaultPT:function(){return w._getPT(h?.pt,void 0,function(v){var k;return v==null||(k=v.directives)===null||k===void 0?void 0:k[t]})},isUnstyled:function(){var v,k;return((v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.unstyled)!==void 0?(k=a._$instances[t])===null||k===void 0||(k=k.$binding)===null||k===void 0||(k=k.value)===null||k===void 0?void 0:k.unstyled:h?.unstyled},theme:function(){var v;return(v=a._$instances[t])===null||v===void 0||(v=v.$primevueConfig)===null||v===void 0?void 0:v.theme},preset:function(){var v;return(v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.dt},ptm:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",B=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return w._getPTValue(a._$instances[t],(v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.pt,k,x({},B))},ptmo:function(){var v=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},k=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",B=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return w._getPTValue(a._$instances[t],v,k,B,!1)},cx:function(){var v,k,B=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",q=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(v=a._$instances[t])!==null&&v!==void 0&&v.isUnstyled()?void 0:w._getOptionValue((k=a._$instances[t])===null||k===void 0||(k=k.$style)===null||k===void 0?void 0:k.classes,B,x({},q))},sx:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",B=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,q=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return B?w._getOptionValue((v=a._$instances[t])===null||v===void 0||(v=v.$style)===null||v===void 0?void 0:v.inlineStyles,k,x({},q)):void 0}},O),a.$instance=a._$instances[t],(m=(b=a.$instance)[l])===null||m===void 0||m.call(b,a,u,d,c),a["$".concat(t)]=a.$instance,w._hook(t,l,a,u,d,c),a.$pd||(a.$pd={}),a.$pd[t]=x(x({},(_=a.$pd)===null||_===void 0?void 0:_[t]),{},{name:t,instance:a._$instances[t]})},r=function(l){var a,u,d,c=l._$instances[t],p=c?.watch,m=function(h){var S,O=h.newValue,E=h.oldValue;return p==null||(S=p.config)===null||S===void 0?void 0:S.call(c,O,E)},b=function(h){var S,O=h.newValue,E=h.oldValue;return p==null||(S=p["config.ripple"])===null||S===void 0?void 0:S.call(c,O,E)};c.$watchersCallback={config:m,"config.ripple":b},p==null||(a=p.config)===null||a===void 0||a.call(c,c?.$primevueConfig),Pe.on("config:change",m),p==null||(u=p["config.ripple"])===null||u===void 0||u.call(c,c==null||(d=c.$primevueConfig)===null||d===void 0?void 0:d.ripple),Pe.on("config:ripple:change",b)},i=function(l){var a=l._$instances[t].$watchersCallback;a&&(Pe.off("config:change",a.config),Pe.off("config:ripple:change",a["config.ripple"]),l._$instances[t].$watchersCallback=void 0)};return{created:function(l,a,u,d){l.$pd||(l.$pd={}),l.$pd[t]={name:t,attrSelector:Ho("pd")},o("created",l,a,u,d)},beforeMount:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("beforeMount",l,a,u,d),r(l)},mounted:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("mounted",l,a,u,d)},beforeUpdate:function(l,a,u,d){o("beforeUpdate",l,a,u,d)},updated:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("updated",l,a,u,d)},beforeUnmount:function(l,a,u,d){var c;i(l),w._removeThemeListeners((c=l.$pd[t])===null||c===void 0?void 0:c.instance),o("beforeUnmount",l,a,u,d)},unmounted:function(l,a,u,d){var c;(c=l.$pd[t])===null||c===void 0||(c=c.instance)===null||c===void 0||(c=c.scopedStyleEl)===null||c===void 0||(c=c.value)===null||c===void 0||c.remove(),o("unmounted",l,a,u,d)}}},extend:function(){var t=w._getMeta.apply(w,arguments),n=Tn(t,2),o=n[0],r=n[1];return x({extend:function(){var s=w._getMeta.apply(w,arguments),l=Tn(s,2),a=l[0],u=l[1];return w.extend(a,x(x(x({},r),r?.methods),u))}},w._extend(o,r))}},sa=`
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
`,la={root:"p-ink"},ua=D.extend({name:"ripple-directive",style:sa,classes:la}),da=w.extend({style:ua});function lt(e){"@babel/helpers - typeof";return lt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},lt(e)}function ca(e){return ba(e)||fa(e)||ma(e)||pa()}function pa(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ma(e,t){if(e){if(typeof e=="string")return Ft(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Ft(e,t):void 0}}function fa(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function ba(e){if(Array.isArray(e))return Ft(e)}function Ft(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function An(e,t,n){return(t=va(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function va(e){var t=ga(e,"string");return lt(t)=="symbol"?t:t+""}function ga(e,t){if(lt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(lt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var ha=da.extend("ripple",{watch:{"config.ripple":function(t){t?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(t){this.remove(t)},timeout:void 0,methods:{bindEvents:function(t){t.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(t){t.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(t){var n=this.getInk(t);n||(n=Mo("span",An(An({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),t.appendChild(n),this.$el=n)},remove:function(t){var n=this.getInk(t);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(t),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(t){var n=this,o=t.currentTarget,r=this.getInk(o);if(!(!r||getComputedStyle(r,null).display==="none")){if(!this.isUnstyled()&&Dt(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"),!ln(r)&&!un(r)){var i=Math.max(Io(o),zo(o));r.style.height=i+"px",r.style.width=i+"px"}var s=Uo(o),l=t.pageX-s.left+document.body.scrollTop-un(r)/2,a=t.pageY-s.top+document.body.scrollLeft-ln(r)/2;r.style.top=a+"px",r.style.left=l+"px",!this.isUnstyled()&&No(r,"p-ink-active"),r.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){r&&(!n.isUnstyled()&&Dt(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(t){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&Dt(t.currentTarget,"p-ink-active"),t.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(t){return t&&t.children?ca(t.children).find(function(n){return Bo(n,"data-pc-name")==="ripple"}):void 0}}}),ya=`
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
`;function ut(e){"@babel/helpers - typeof";return ut=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ut(e)}function be(e,t,n){return(t=_a(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function _a(e){var t=Sa(e,"string");return ut(t)=="symbol"?t:t+""}function Sa(e,t){if(ut(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ut(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var ka={root:function(t){var n=t.instance,o=t.props;return["p-button p-component",be(be(be(be(be(be(be(be(be({"p-button-icon-only":n.hasIcon&&!o.label&&!o.badge,"p-button-vertical":(o.iconPos==="top"||o.iconPos==="bottom")&&o.label,"p-button-loading":o.loading,"p-button-link":o.link||o.variant==="link"},"p-button-".concat(o.severity),o.severity),"p-button-raised",o.raised),"p-button-rounded",o.rounded),"p-button-text",o.text||o.variant==="text"),"p-button-outlined",o.outlined||o.variant==="outlined"),"p-button-sm",o.size==="small"),"p-button-lg",o.size==="large"),"p-button-plain",o.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(t){var n=t.props;return["p-button-icon",be({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},wa=D.extend({name:"button",style:ya,classes:ka}),$a={name:"BaseButton",extends:Zt,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:wa,provide:function(){return{$pcButton:this,$parentInstance:this}}};function dt(e){"@babel/helpers - typeof";return dt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},dt(e)}function Z(e,t,n){return(t=Pa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Pa(e){var t=Oa(e,"string");return dt(t)=="symbol"?t:t+""}function Oa(e,t){if(dt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(dt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Be={name:"Button",extends:$a,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(t){var n=t==="root"?this.ptmi:this.ptm;return n(t,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return J(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return Ee(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return Qe(Z(Z(Z(Z(Z(Z(Z(Z(Z(Z({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return Qe(Z(Z({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return Qe(Z(Z({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:Yn,Badge:Qn},directives:{ripple:ha}},Ta=["data-p"],xa=["data-p"];function Ca(e,t,n,o,r,i){var s=Ut("SpinnerIcon"),l=Ut("Badge"),a=po("ripple");return e.asChild?Ke(e.$slots,"default",{key:1,class:xe(e.cx("root")),a11yAttrs:i.a11yAttrs}):mo((T(),Me(fo(e.as),J({key:0,class:e.cx("root"),"data-p":i.dataP},i.attrs),{default:Ve(function(){return[Ke(e.$slots,"default",{},function(){return[e.loading?Ke(e.$slots,"loadingicon",J({key:0,class:[e.cx("loadingIcon"),e.cx("icon")]},e.ptm("loadingIcon")),function(){return[e.loadingIcon?(T(),L("span",J({key:0,class:[e.cx("loadingIcon"),e.cx("icon"),e.loadingIcon]},e.ptm("loadingIcon")),null,16)):(T(),Me(s,J({key:1,class:[e.cx("loadingIcon"),e.cx("icon")],spin:""},e.ptm("loadingIcon")),null,16,["class"]))]}):Ke(e.$slots,"icon",J({key:1,class:[e.cx("icon")]},e.ptm("icon")),function(){return[e.icon?(T(),L("span",J({key:0,class:[e.cx("icon"),e.icon,e.iconClass],"data-p":i.dataIconP},e.ptm("icon")),null,16,Ta)):F("",!0)]}),e.label?(T(),L("span",J({key:2,class:e.cx("label")},e.ptm("label"),{"data-p":i.dataLabelP}),X(e.label),17,xa)):F("",!0),e.badge?(T(),Me(l,{key:3,value:e.badge,class:xe(e.badgeClass),severity:e.badgeSeverity,unstyled:e.unstyled,pt:e.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):F("",!0)]})]}),_:3},16,["class","data-p"])),[[a]])}Be.render=Ca;const Zn=Symbol("host_api"),Jn=Symbol("axios"),Xn=Symbol("proxy"),Aa=Symbol("config"),La=Symbol("on_subscription");function Ea(){const e=Gt(Zn);if(!e)throw new Error("HostApi not provided");return e}function ja(){const e=Gt(Jn);if(!e)throw new Error("ProxyApiInstance not provided");return e}function Na(){const e=Gt(Xn);if(!e)throw new Error("WIPPY_INSTANCE not provided");return e}const Di={changeset:"keeper.changeset",git:"keeper.git",version:"registry:version"};async function Ia(e){const{data:t}=await e.post("/api/v1/keeper/events/subscribe",{});return t}async function Da(e){const{data:t}=await e.post("/api/v1/keeper/events/unsubscribe",{});return t}const Jt="keeper.events.muted",Ue=M(!1),Tt=M(localStorage.getItem(Jt)==="1"),kt=M(!1),ct=M(null);function eo(e){return e?.response?.data?.error||e?.message||"request failed"}async function to(e,t=!1){if(!(Tt.value||kt.value)&&!(Ue.value&&!t)){kt.value=!0;try{const n=await Ia(e);Ue.value=n.subscribed===!0,ct.value=null}catch(n){Ue.value=!1,ct.value=eo(n)}finally{kt.value=!1}}}async function Ra(e){if(Tt.value=!0,localStorage.setItem(Jt,"1"),!!Ue.value)try{await Da(e),Ue.value=!1,ct.value=null}catch(t){ct.value=eo(t)}}async function Ma(e){Tt.value=!1,localStorage.removeItem(Jt),await to(e,!0)}function Va(){return{subscribed:Ue,muted:Tt,pending:kt,error:ct,ensureSubscribed:to,mute:Ra,unmute:Ma}}async function Ri(e){const{data:t}=await e.get("/api/v1/keeper/registry/namespaces");return t}async function Mi(e,t={}){const n={limit:t.limit||200,offset:t.offset||0};t.namespace&&(n.namespace=t.namespace),t.kind&&(n.kind=t.kind),t.metaType&&(n["meta.type"]=t.metaType),t.query&&(n.q=t.query);const{data:o}=await e.get("/api/v1/keeper/registry/entries",{params:n});return o}async function Vi(e,t){const{data:n}=await e.get("/api/v1/keeper/registry/entry",{params:{id:t}});return n}async function Bi(e,t,n){const{data:o}=await e.put("/api/v1/keeper/registry/entry",n,{params:{id:t}});return o}async function Ui(e,t){const n={};t&&(n.namespace=t);const{data:o}=await e.get("/api/v1/keeper/state/graph",{params:n});return o}async function zi(e){const{data:t}=await e.get("/api/v1/keeper/env/list");return t}async function Wi(e,t,n){const{data:o}=await e.post("/api/v1/keeper/env/set",{key:t,value:n});return o}async function qi(e){const{data:t}=await e.get("/api/v1/keeper/sync/state");return t}async function Hi(e){const{data:t}=await e.get("/api/v1/keeper/sync/config");return t}async function Ki(e,t){const{data:n}=await e.put("/api/v1/keeper/sync/config",{managed_namespaces:t});return n}async function Fi(e){const{data:t}=await e.post("/api/v1/keeper/sync/download");return t}async function Gi(e){const{data:t}=await e.post("/api/v1/keeper/sync/upload");return t}async function Yi(e){const{data:t}=await e.post("/api/v1/keeper/sync/undo");return t}async function Qi(e){const{data:t}=await e.post("/api/v1/keeper/sync/redo");return t}const Vt={"ns.definition":"var(--p-info-500)","ns.requirement":"var(--p-warn-500)","ns.dependency":"var(--p-accent-400)","http.service":"var(--p-success-500)","http.router":"var(--p-success-500)","http.endpoint":"var(--p-info-500)","http.static":"var(--p-info-500)","function.lua":"var(--p-warn-500)","library.lua":"var(--p-warn-500)","process.lua":"var(--p-warn-500)","registry.entry":"var(--p-accent-500)","db.sql.sqlite":"var(--p-accent-500)","fs.directory":"var(--p-text-muted-color)","fs.embed":"var(--p-text-muted-color)","process.host":"var(--p-info-500)","store.memory":"var(--p-accent-500)","store.sql":"var(--p-accent-500)","env.variable":"var(--p-text-muted-color)","env.composite":"var(--p-text-muted-color)","env.file":"var(--p-text-muted-color)","env.os":"var(--p-text-muted-color)","env.memory":"var(--p-text-muted-color)","security.policy":"var(--p-danger-500)","view.page":"var(--p-info-500)","view.component":"var(--p-info-500)","queue.memory":"var(--p-accent-500)","queue.consumer":"var(--p-accent-500)","template.set":"var(--p-warn-500)",contract:"var(--p-accent-400)","agent.gen1":"var(--p-warn-500)","agent.trait":"var(--p-warn-500)","llm.model":"var(--p-accent-500)",tool:"var(--p-info-500)"},Bt={"ns.definition":"tabler:package","ns.requirement":"tabler:plug","ns.dependency":"tabler:link","http.service":"tabler:server","http.router":"tabler:route","http.endpoint":"tabler:api","http.static":"tabler:file","function.lua":"tabler:code","library.lua":"tabler:book","process.lua":"tabler:code","registry.entry":"tabler:database","db.sql.sqlite":"tabler:database","fs.directory":"tabler:folder","fs.embed":"tabler:folder","process.host":"tabler:cpu","store.memory":"tabler:database","store.sql":"tabler:database","env.variable":"tabler:variable","env.composite":"tabler:variable","env.file":"tabler:variable","env.os":"tabler:variable","env.memory":"tabler:variable","security.policy":"tabler:shield-check","view.page":"tabler:browser","view.component":"tabler:components","queue.memory":"tabler:list","queue.consumer":"tabler:player-play","template.set":"tabler:template",contract:"tabler:file-certificate","agent.gen1":"tabler:robot","agent.trait":"tabler:sparkles","llm.model":"tabler:brain",tool:"tabler:tool"};function wt(e,t){return t&&Vt[t]?Vt[t]:Vt[e]||"var(--p-text-muted-color)"}function no(e,t){return t&&Bt[t]?Bt[t]:Bt[e]||"tabler:circle"}async function Zi(e,t=100,n=0){const{data:o}=await e.get("/api/v1/sessions",{params:{limit:t,offset:n}});return o}async function Ji(e,t){const{data:n}=await e.get("/api/v1/sessions/get",{params:{session_id:t}});return n}async function Xi(e,t,n=50,o=""){const{data:r}=await e.get("/api/v1/sessions/messages",{params:{session_id:t,limit:n,cursor:o}});return r}function es(e){return!e||e===0?"0":e>=1e6?(e/1e6).toFixed(1)+"M":e>=1e3?(e/1e3).toFixed(1)+"K":e.toString()}function Ln(e){if(!e)return"";let t;typeof e=="number"?e>1e15?t=e/1e6:e>1e12?t=e/1e3:e>1e10?t=e:t=e*1e3:t=new Date(e).getTime();const n=new Date(t);if(isNaN(n.getTime()))return"";const r=Math.floor((new Date().getTime()-n.getTime())/1e3);if(r<60)return"just now";const i=Math.floor(r/60);if(i<60)return`${i}m ago`;const s=Math.floor(i/60);if(s<24)return`${s}h ago`;const l=Math.floor(s/24);if(l<30)return`${l}d ago`;const a=Math.floor(l/30);return a<12?`${a}mo ago`:`${Math.floor(a/12)}y ago`}function ts(e){return e?new Date(typeof e=="number"?e*1e3:e).toLocaleString():"N/A"}const Ba={key:0,class:"status-dropdown"},Ua=["onClick"],za={key:0,class:"plugin-tag",title:"Provided by a registered plugin"},Wa=Le({__name:"AppNavDropdown",props:{icon:{},label:{},items:{},open:{type:Boolean},active:{type:Boolean},currentName:{},wrapClass:{}},emits:["toggle","navigate"],setup(e,{emit:t}){const n=t;function o(r){n("navigate",r)}return(r,i)=>(T(),L("div",{class:xe(["relative",e.wrapClass])},[N(C(Be),{variant:"text",class:xe(["k-btn-nav relative !gap-1.5",{"k-btn-active":e.active}]),onClick:i[0]||(i[0]=s=>n("toggle"))},{default:Ve(()=>[N(C(K),{icon:e.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Ze(" "+X(e.label)+" ",1),N(C(K),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.5"}})]),_:1},8,["class"]),e.open?(T(),L("div",Ba,[(T(!0),L(Je,null,Xe(e.items,s=>(T(),L("button",{key:s.name,class:xe(["status-item",{"status-item--active":e.currentName===s.name}]),onClick:l=>o(s.path)},[N(C(K),{icon:s.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Ze(" "+X(s.label)+" ",1),s.name.startsWith("plugin:")?(T(),L("span",za,"plugin")):F("",!0)],10,Ua))),128))])):F("",!0)],2))}}),Xt=(e,t)=>{const n=e.__vccOpts||e;for(const[o,r]of t)n[o]=r;return n},He=Xt(Wa,[["__scopeId","data-v-6d403115"]]),qa={class:"truncate",style:{"max-width":"80px"}},Ha={key:1,class:"relative agent-dropdown-wrap"},Ka={key:0,class:"agent-dropdown"},Fa=["onClick"],Ga={class:"agent-item-copy"},Ya={class:"agent-item-title"},Qa={key:0,class:"agent-item-comment"},Za=Le({__name:"AppAgentLauncher",props:{agents:{},open:{type:Boolean}},emits:["toggle","start"],setup(e,{emit:t}){const n=t;return(o,r)=>e.agents.length===1?(T(),L("button",{key:0,class:"ask-btn",onClick:r[0]||(r[0]=i=>n("start",e.agents[0].start_token))},[N(C(K),{icon:e.agents[0].icon||"tabler:message-bolt",class:"w-3.5 h-3.5"},null,8,["icon"]),V("span",qa,X(e.agents[0].title||"Ask"),1)])):e.agents.length>1?(T(),L("div",Ha,[V("button",{class:"ask-btn",onClick:r[1]||(r[1]=i=>n("toggle"))},[N(C(K),{icon:"tabler:message-bolt",class:"w-3.5 h-3.5"}),r[2]||(r[2]=Ze(" Ask ",-1)),N(C(K),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.6"}})]),e.open?(T(),L("div",Ka,[(T(!0),L(Je,null,Xe(e.agents,i=>(T(),L("button",{key:i.id,class:"agent-item",onClick:s=>n("start",i.start_token)},[N(C(K),{icon:i.icon||"tabler:robot",class:"agent-item-icon"},null,8,["icon"]),V("span",Ga,[V("span",Ya,X(i.title||i.id),1),i.comment?(T(),L("span",Qa,X(i.comment),1)):F("",!0)])],8,Fa))),128))])):F("",!0)])):F("",!0)}}),Ja=Xt(Za,[["__scopeId","data-v-eeb14e8e"]]),Xa={key:0,class:"flex items-center gap-1.5 text-xs pl-2",style:{color:"var(--p-text-muted-color)","border-left":"1px solid var(--p-content-border-color)"}},ei={class:"truncate max-w-[100px]"},ti=Le({__name:"AppUserChip",props:{user:{}},emits:["logout"],setup(e,{emit:t}){const n=t;return(o,r)=>e.user?(T(),L("div",Xa,[V("span",ei,X(e.user.full_name||e.user.email),1),N(C(Be),{class:"k-btn-icon !w-6 !h-6 !p-0 !rounded-full",title:"Logout",onClick:r[0]||(r[0]=i=>n("logout"))},{default:Ve(()=>[N(C(K),{icon:"tabler:logout",class:"w-3 h-3"})]),_:1})])):F("",!0)}}),ni={class:"search-modal"},oi={class:"search-header"},ri=["value"],ai={key:0,class:"search-results"},ii=["onClick"],si={class:"flex-1 min-w-0"},li={class:"text-[11px] font-mono truncate",style:{color:"var(--p-text-color)"}},ui={key:0,class:"text-[9px] truncate",style:{color:"var(--p-text-muted-color)"}},di={key:1,class:"search-empty"},ci={key:2,class:"search-hints"},pi=["onClick"],mi={class:"text-[10px] font-mono",style:{color:"var(--p-primary-color)"}},fi={class:"text-[10px]",style:{color:"var(--p-text-muted-color)"}},bi=Le({__name:"AppGlobalSearch",props:{open:{type:Boolean},query:{},results:{},loading:{type:Boolean},hints:{}},emits:["update:query","close","search-input","select","apply-hint"],setup(e,{emit:t}){const n=t;function o(r){r.length>0&&n("select",r[0])}return(r,i)=>(T(),Me(bo,{to:"body"},[e.open?(T(),L("div",{key:0,class:"search-overlay",onClick:i[3]||(i[3]=vo(s=>n("close"),["self"]))},[V("div",ni,[V("div",oi,[N(C(K),{icon:"tabler:search",class:"w-4 h-4 shrink-0",style:{color:"var(--p-text-muted-color)"}}),V("input",{value:e.query,onInput:i[0]||(i[0]=s=>{n("update:query",s.target.value),n("search-input")}),onKeydown:[i[1]||(i[1]=on(s=>n("close"),["escape"])),i[2]||(i[2]=on(s=>o(e.results),["enter"]))],class:"global-search-input",placeholder:"Search entries, functions, configs...",autofocus:""},null,40,ri),e.loading?(T(),Me(C(K),{key:0,icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin",style:{color:"var(--p-primary-color)"}})):F("",!0),i[4]||(i[4]=V("kbd",{class:"search-kbd"},"Esc",-1))]),e.results.length>0?(T(),L("div",ai,[(T(!0),L(Je,null,Xe(e.results,s=>(T(),L("div",{key:s.id,class:"search-item",onClick:l=>n("select",s)},[N(C(K),{icon:s.icon||C(no)(s.kind),class:"w-3 h-3 shrink-0",style:zt({color:s.color||C(wt)(s.kind)})},null,8,["icon","style"]),V("div",si,[V("div",li,X(s.id),1),s.snippet?(T(),L("div",ui,X(s.snippet),1)):F("",!0)]),V("span",{class:"text-[8px] px-1 rounded",style:zt({color:s.color||C(wt)(s.kind),background:`color-mix(in srgb, ${s.color||C(wt)(s.kind)} 12%, transparent)`})},X(s.kind),5)],8,ii))),128))])):e.query&&!e.loading?(T(),L("div",di,"No results")):e.query?F("",!0):(T(),L("div",ci,[(T(!0),L(Je,null,Xe(e.hints,s=>(T(),L("div",{key:s.prefix,class:"search-hint",onClick:l=>n("apply-hint",s.prefix)},[N(C(K),{icon:s.icon,class:"w-3 h-3 shrink-0",style:{color:"var(--p-text-muted-color)"}},null,8,["icon"]),V("span",mi,X(s.prefix||"*"),1),V("span",fi,X(s.desc),1)],8,pi))),128))]))])])):F("",!0)]))}}),vi={class:"h-full flex flex-col"},gi={class:"shrink-0 h-10 flex items-center px-3 gap-3",style:{background:"var(--p-content-background)","border-bottom":"1px solid var(--p-content-border-color)"}},hi={class:"flex items-center gap-0.5 flex-1"},yi={class:"flex items-center gap-1.5 shrink-0"},_i={key:0,class:"activity-live"},Si={class:"flex-1 overflow-y-auto",style:{background:"color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)"}},ki=Le({__name:"app",setup(e){const t=Nn(),n=yo(),o=ja(),r=Ea(),i=Na(),s=Va(),l=s.subscribed,a=s.muted,u=M(0),d=M(0);let c=null,p=null,m=null;async function b(){try{const{data:f}=await o.get("/api/v1/keeper/logger/stats");f.success&&f.stats?.counters&&(u.value=f.stats.counters.error||0,d.value=f.stats.counters.warn||0)}catch{}}const _=[{path:"/",name:"dashboard",label:"Home",icon:"tabler:layout-dashboard"}],h=[{path:"/settings/environment",name:"settings-environment",label:"Environment",icon:"tabler:variable"},{path:"/settings/registry",name:"settings-registry",label:"Registry",icon:"tabler:database"},{path:"/settings/hub",name:"settings-hub",label:"Wippy Hub",icon:"tabler:cloud"},{path:"/mcp",name:"mcp",label:"MCP",icon:"tabler:plug-connected"}],S=[{path:"/sessions",name:"sessions",label:"Sessions",icon:"tabler:list"},{path:"/dataflows",name:"workflow",label:"Dataflows",icon:"tabler:git-merge"},{path:"/system",name:"system",label:"System",icon:"tabler:activity"},{path:"/logs",name:"logs",label:"Logs",icon:"tabler:file-text"}],O=[],E=[{path:"/structure",name:"structure",label:"Registry",icon:"tabler:binary-tree"},{path:"/agents",name:"agents",label:"Agents",icon:"tabler:robot"},{path:"/models",name:"models",label:"Models",icon:"tabler:brain"},{path:"/tools",name:"tools",label:"Tools",icon:"tabler:tool"},{path:"/traits",name:"traits",label:"Traits",icon:"tabler:sparkles"},{path:"/endpoints",name:"endpoints",label:"Endpoints",icon:"tabler:api"},{path:"/policies",name:"policies",label:"Policies",icon:"tabler:shield-check"}],v=[{path:"/tasks",name:"tasks",label:"Pipeline",icon:"tabler:git-merge"},{path:"/changes",name:"changes",label:"Changes",icon:"tabler:git-branch"},{path:"/components",name:"components",label:"Components",icon:"tabler:puzzle"},{path:"/knowledge",name:"knowledge",label:"Knowledge",icon:"tabler:brain"},{path:"/tests",name:"tests",label:"Tests",icon:"tabler:test-pipe"}],k=M([]);async function B(){try{const{data:f}=await o.get("/api/public/pages/list");if(!f?.success||!Array.isArray(f.pages))return;k.value=f.pages.filter(g=>g.announced&&g.id.startsWith("keeper.")&&g.id!=="keeper:main").sort((g,ie)=>(g.order||9999)-(ie.order||9999)||g.title.localeCompare(ie.title)).map(g=>({path:`/plugin/${g.id}`,name:`plugin:${g.id}`,label:g.title||g.name,icon:g.icon||"tabler:puzzle",group:g.group||"develop"}))}catch{}}const q=H(()=>[...S,...k.value.filter(f=>f.group==="observe")]),ue=H(()=>[...E,...k.value.filter(f=>f.group==="structure")]),de=H(()=>[...v,...k.value.filter(f=>f.group==="develop"||!f.group)]),ce=H(()=>[...O,...k.value.filter(f=>f.group==="status")]),G=M(!1),te=M(!1),ne=M(!1),Y=M(!1),oe=M(!1),re=M(!1),he=H(()=>new Set(ce.value.map(f=>f.name))),_e=H(()=>new Set(ue.value.map(f=>f.name))),Se=H(()=>new Set(de.value.map(f=>f.name))),pe=H(()=>new Set(q.value.map(f=>f.name))),le=H(()=>new Set(h.map(f=>f.name))),R=H(()=>n.name),je=H(()=>he.value.has(String(R.value))),ke=H(()=>_e.value.has(String(R.value))),mt=H(()=>Se.value.has(String(R.value))),ft=H(()=>pe.value.has(String(R.value))||R.value==="session-detail"||R.value==="dataflow-detail"),xt=H(()=>le.value.has(String(R.value))||R.value==="settings"),bt=M(null);function Ne(f){t.push(f)}function Ct(){G.value=!1,te.value=!1,ne.value=!1,Y.value=!1,oe.value=!1,re.value=!1}function Oe(f){Ne(f),Ct()}async function At(){try{const{data:f}=await o.get("/api/v1/user/me");f.success&&f.user&&(bt.value={email:f.user.email,full_name:f.user.full_name})}catch{}}const vt=M([]);async function Lt(){try{const{data:f}=await o.get("/api/v1/keeper/agents/list",{params:{public_only:!0}});vt.value=f.agents||[]}catch{}}function Et(f){r.startChat(f,{sidebar:!0}),re.value=!1}const we=M(!1),Te=M(""),ae=M([]),ze=M(!1);let We=null;const jt=[{prefix:"session:",desc:"Search sessions by title or ID",icon:"tabler:list"},{prefix:"dataflow:",desc:"Search dataflows",icon:"tabler:git-merge"},{prefix:"agent:",desc:"Search agents",icon:"tabler:robot"},{prefix:"model:",desc:"Search LLM models",icon:"tabler:brain"},{prefix:"tool:",desc:"Search tools",icon:"tabler:tool"},{prefix:"endpoint:",desc:"Search HTTP endpoints",icon:"tabler:api"},{prefix:"",desc:"Search all registry entries",icon:"tabler:search"}];async function gt(){const f=Te.value.trim();if(!f){ae.value=[];return}ze.value=!0;try{const g=f.indexOf(":"),ie=g>0?f.slice(0,g).toLowerCase():"",$=g>0?f.slice(g+1).trim():f;if(ie==="session"){const{data:Q}=await o.get("/api/v1/sessions",{params:{limit:20}}),U=(Q.sessions||[]).filter(y=>!$||y.title?.toLowerCase().includes($.toLowerCase())||y.session_id?.includes($)||y.current_agent?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.title||y.session_id?.slice(0,12)+"...",kind:y.current_agent||"session",snippet:[y.current_model,y.status,Ln(y.last_message_date||y.start_date)].filter(Boolean).join(" · "),icon:"tabler:message",color:"var(--p-info-500)",route:"/session/"+y.session_id}))}else if(ie==="dataflow"){const{data:Q}=await o.get("/api/v1/dataflows",{params:{limit:20}}),U=(Q.dataflows||[]).filter(y=>!$||y.metadata?.title?.toLowerCase().includes($.toLowerCase())||y.dataflow_id?.includes($));ae.value=U.slice(0,15).map(y=>({id:y.metadata?.title||y.dataflow_id?.slice(0,12)+"...",kind:y.status||"dataflow",snippet:[y.type,Ln(y.created_at)].filter(Boolean).join(" · "),icon:"tabler:git-merge",color:y.status==="running"?"var(--p-success-500)":y.status==="failed"?"var(--p-danger-500)":"var(--p-info-500)",route:"/dataflow/"+y.dataflow_id}))}else if(ie==="agent"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"agent.gen1",limit:100}}),U=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.title||"",icon:"tabler:robot",color:"var(--p-warn-500)",route:"/structure?entry="+y.id}))}else if(ie==="model"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"llm.model",limit:100}}),U=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.title||"",icon:"tabler:brain",color:"var(--p-accent-500)",route:"/structure?entry="+y.id}))}else if(ie==="tool"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"tool",limit:100}}),U=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.comment||y.meta?.llm_alias||"",icon:"tabler:tool",color:"var(--p-info-500)",route:"/structure?entry="+y.id}))}else if(ie==="endpoint"){const{data:Q}=await o.get("/api/v1/keeper/registry/entries",{params:{kind:"http.endpoint",limit:200}}),U=(Q.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.comment||"",icon:"tabler:api",color:"var(--p-info-500)",route:"/structure?entry="+y.id}))}else{const{data:Q}=await o.get("/api/v1/keeper/state/search",{params:{q:f,limit:30}});ae.value=(Q.results||[]).map(U=>({id:U.id,kind:U.kind,snippet:U.snippet,icon:no(U.kind),color:wt(U.kind),route:"/structure?entry="+U.id}))}}catch{ae.value=[]}finally{ze.value=!1}}function Nt(){We&&clearTimeout(We),We=window.setTimeout(gt,300)}function It(f){Te.value=f,gt(),window.setTimeout(()=>{const g=document.querySelector(".global-search-input");g&&(g.focus(),g.setSelectionRange(f.length,f.length))},10)}function oo(f){if(we.value=!1,Te.value="",ae.value=[],f.route)if(f.route.includes("?")){const[g,ie]=f.route.split("?"),$=Object.fromEntries(new URLSearchParams(ie));t.push({path:g,query:$})}else t.push(f.route)}function en(f){(f.ctrlKey||f.metaKey)&&f.shiftKey&&(f.key==="F"||f.key==="f")&&(f.preventDefault(),we.value=!0,setTimeout(()=>document.querySelector(".global-search-input")?.focus(),50)),f.key==="Escape"&&we.value&&(we.value=!1)}function ro(){r.logout()}De(()=>n.fullPath,()=>{try{const f={page:n.name,path:n.fullPath};n.query.entry&&(f.selected_entry=n.query.entry),n.query.ns&&(f.namespace=n.query.ns),r.setContext(f)}catch{}});function tn(f){const g=f.target;g.closest(".status-dropdown-wrap")||(G.value=!1),g.closest(".structure-dropdown-wrap")||(te.value=!1),g.closest(".develop-dropdown-wrap")||(ne.value=!1),g.closest(".observe-dropdown-wrap")||(Y.value=!1),g.closest(".settings-dropdown-wrap")||(oe.value=!1),g.closest(".agent-dropdown-wrap")||(re.value=!1)}return jn(()=>{c=i.on("action:navigate",f=>{const g=f?.data?.path||f?.path;g&&t.push(g)}),p=i.on("keeper.logs",f=>{const g=f?.data?.counters||f?.counters;g&&(u.value=g.error||0,d.value=g.warn||0)}),m=i.on("welcome",()=>s.ensureSubscribed(o,!0)),At(),b(),Lt(),B(),s.ensureSubscribed(o,!0),document.addEventListener("click",tn),document.addEventListener("keydown",en)}),go(()=>{m?.(),c?.(),p?.(),document.removeEventListener("click",tn),document.removeEventListener("keydown",en)}),(f,g)=>{const ie=Ut("router-view");return T(),L("div",vi,[V("header",gi,[N(C(Be),{variant:"text",class:"shrink-0 !gap-1.5",onClick:g[0]||(g[0]=$=>Ne("/"))},{default:Ve(()=>[N(C(K),{icon:"tabler:shield-code",class:"w-4 h-4"}),g[10]||(g[10]=V("span",{class:"text-xs font-bold tracking-wider font-mono"},"KEEPER",-1))]),_:1}),V("nav",hi,[(T(),L(Je,null,Xe(_,$=>N(C(Be),{key:$.name,variant:"text",class:xe(["k-btn-nav relative !gap-1.5",{"k-btn-active":R.value===$.name}]),onClick:Q=>Ne($.path)},{default:Ve(()=>[N(C(K),{icon:$.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Ze(" "+X($.label),1)]),_:2},1032,["class","onClick"])),64)),N(He,{icon:"tabler:eye",label:"Observe","wrap-class":"observe-dropdown-wrap",items:q.value,open:Y.value,active:ft.value,"current-name":R.value,onToggle:g[1]||(g[1]=$=>Y.value=!Y.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),N(He,{icon:"tabler:binary-tree",label:"Structure","wrap-class":"structure-dropdown-wrap",items:ue.value,open:te.value,active:ke.value,"current-name":R.value,onToggle:g[2]||(g[2]=$=>te.value=!te.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),N(He,{icon:"tabler:code",label:"Develop","wrap-class":"develop-dropdown-wrap",items:de.value,open:ne.value,active:mt.value,"current-name":R.value,onToggle:g[3]||(g[3]=$=>ne.value=!ne.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),ce.value.length?(T(),Me(He,{key:0,icon:"tabler:heart-rate-monitor",label:"Status","wrap-class":"status-dropdown-wrap",items:ce.value,open:G.value,active:je.value,"current-name":R.value,onToggle:g[4]||(g[4]=$=>G.value=!G.value),onNavigate:Oe},null,8,["items","open","active","current-name"])):F("",!0),N(He,{icon:"tabler:settings",label:"Settings","wrap-class":"settings-dropdown-wrap",items:h,open:oe.value,active:xt.value,"current-name":R.value,onToggle:g[5]||(g[5]=$=>oe.value=!oe.value),onNavigate:Oe},null,8,["open","active","current-name"])]),V("div",yi,[N(C(Be),{variant:"text",class:xe(["k-btn-icon !rounded relative",{"k-btn-active":R.value==="activity"}]),title:C(a)?"Admin activity — muted":C(l)?"Admin activity — live":"Admin activity",onClick:g[6]||(g[6]=$=>Ne("/activity"))},{default:Ve(()=>[N(C(K),{icon:C(a)?"tabler:broadcast-off":"tabler:broadcast",class:"w-4 h-4",style:zt({color:C(l)&&!C(a)?"var(--p-primary-color)":"var(--p-text-muted-color)"})},null,8,["icon","style"]),C(l)&&!C(a)?(T(),L("span",_i)):F("",!0)]),_:1},8,["class","title"]),N(Ja,{agents:vt.value,open:re.value,onToggle:g[7]||(g[7]=$=>re.value=!re.value),onStart:Et},null,8,["agents","open"]),N(ti,{user:bt.value,onLogout:ro},null,8,["user"])])]),V("main",Si,[N(ie)]),N(bi,{open:we.value,query:Te.value,results:ae.value,loading:ze.value,hints:jt,"onUpdate:query":g[8]||(g[8]=$=>Te.value=$),onClose:g[9]||(g[9]=$=>we.value=!1),onSearchInput:Nt,onSelect:oo,onApplyHint:It},null,8,["open","query","results","loading"])])}}}),wi=Xt(ki,[["__scopeId","data-v-ea1b5e2c"]]),$i="modulepreload",Pi=function(e,t){return new URL(e,t).href},En={},A=function(t,n,o){let r=Promise.resolve();if(n&&n.length>0){let s=function(d){return Promise.all(d.map(c=>Promise.resolve(c).then(p=>({status:"fulfilled",value:p}),p=>({status:"rejected",reason:p}))))};const l=document.getElementsByTagName("link"),a=document.querySelector("meta[property=csp-nonce]"),u=a?.nonce||a?.getAttribute("nonce");r=s(n.map(d=>{if(d=Pi(d,o),d in En)return;En[d]=!0;const c=d.endsWith(".css"),p=c?'[rel="stylesheet"]':"";if(!!o)for(let _=l.length-1;_>=0;_--){const h=l[_];if(h.href===d&&(!c||h.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${d}"]${p}`))return;const b=document.createElement("link");if(b.rel=c?"stylesheet":$i,c||(b.as="script"),b.crossOrigin="",b.href=d,u&&b.setAttribute("nonce",u),document.head.appendChild(b),c)return new Promise((_,h)=>{b.addEventListener("load",_),b.addEventListener("error",()=>h(new Error(`Unable to preload CSS for ${d}`)))})}))}function i(s){const l=new Event("vite:preloadError",{cancelable:!0});if(l.payload=s,window.dispatchEvent(l),!l.defaultPrevented)throw s}return r.then(s=>{for(const l of s||[])l.status==="rejected"&&i(l.reason);return t().catch(i)})};function Oi(e,t={}){const n=t.host??$t,o=t.on===void 0?wo:t.on,r=_o();t.initialPath&&r.replace(t.initialPath);const i=So({history:r,routes:e});$o(l=>i.resolve(l));let s;return i.afterEach(l=>{const a=s;s=void 0,n.onRouteChanged(l.fullPath,a)}),o&&o("@history",({path:l,navId:a})=>{if(!l)return;a!==void 0&&(s=a);const u=l.startsWith("/")?l:`/${l}`;i.currentRoute.value.fullPath!==u&&i.push(u)}),i}Le({name:"WippyHostRouterLink",props:{to:{type:String,required:!0}},setup(e,{slots:t}){return()=>Fe("a",{href:e.to,onClick:n=>{n.defaultPrevented||n.button!==0||n.metaKey||n.altKey||n.ctrlKey||n.shiftKey||(n.preventDefault(),$t.navigate(e.to))}},t.default?.())}});Le({name:"WippyAutoRouterLink",props:{to:{type:[String,Object],required:!0},replace:{type:Boolean,default:!1},activeClass:{type:String,default:void 0},exactActiveClass:{type:String,default:void 0},ariaCurrentValue:{type:String,default:"page"},externalTarget:{type:String,default:"_blank"}},setup(e,{slots:t}){const n=Nn();return()=>{const o=n.resolve(e.to),r=$t.classifyLink(o.href);if(r.kind==="host-nav")return Fe("a",{href:o.href,onClick:i=>{i.defaultPrevented||i.button===0&&(i.metaKey||i.altKey||i.ctrlKey||i.shiftKey||(i.preventDefault(),$t.navigate(r.normalizedPath??r.href)))},"aria-current":e.ariaCurrentValue},t.default?.());if(r.kind==="external"){const i=e.externalTarget==="_blank";return Fe("a",{href:o.href,target:e.externalTarget||void 0,rel:i?"noopener noreferrer":void 0},t.default?.())}return r.kind==="ignore"?Fe("a",{href:o.href||"#",onClick:i=>i.preventDefault()},t.default?.()):Fe(ko,{to:e.to,replace:e.replace,activeClass:e.activeClass,exactActiveClass:e.exactActiveClass,ariaCurrentValue:e.ariaCurrentValue},t.default?{default:i=>t.default?.(i)}:void 0)}}});const Ti=[{path:"/",name:"dashboard",component:()=>A(()=>import("./assets/dashboard-CSK4-BTI.js"),__vite__mapDeps([0,1,2,3,4,5,6,7,8]),import.meta.url)},{path:"/dataflows",name:"workflow",component:()=>A(()=>import("./assets/workflow-BnPrisCC.js"),__vite__mapDeps([9,3]),import.meta.url)},{path:"/sessions",name:"sessions",component:()=>A(()=>import("./assets/sessions-BrMpENKd.js"),__vite__mapDeps([10,11]),import.meta.url)},{path:"/session/:id",name:"session-detail",component:()=>A(()=>import("./assets/session-detail-CDshxVJR.js"),__vite__mapDeps([12,1,13,14,15]),import.meta.url)},{path:"/agents",name:"agents",component:()=>A(()=>import("./assets/agents-Pl02yESY.js"),__vite__mapDeps([16,1,8,17,14,15,11]),import.meta.url)},{path:"/models",name:"models",component:()=>A(()=>import("./assets/models-B3DPFv9Z.js"),__vite__mapDeps([18,1,8,17,14,15,11]),import.meta.url)},{path:"/tools",name:"tools",component:()=>A(()=>import("./assets/tools-page-D8Jt7la8.js"),__vite__mapDeps([19,1,8,17,14,15,11]),import.meta.url)},{path:"/traits",name:"traits",component:()=>A(()=>import("./assets/traits-BW2MPbA7.js"),__vite__mapDeps([20,1,8,17,14,15,11]),import.meta.url)},{path:"/endpoints",name:"endpoints",component:()=>A(()=>import("./assets/endpoints-B9BCTqnt.js"),__vite__mapDeps([21,1,17,14,15,11]),import.meta.url)},{path:"/policies",name:"policies",component:()=>A(()=>import("./assets/policies-BgLUSNmY.js"),__vite__mapDeps([22,1,8,17,14,15,11]),import.meta.url)},{path:"/structure",name:"structure",component:()=>A(()=>import("./assets/structure-BoeDRm0U.js"),__vite__mapDeps([23,8]),import.meta.url)},{path:"/dataflow/:id",name:"dataflow-detail",component:()=>A(()=>import("./assets/dataflow-detail-CBigbUg1.js"),__vite__mapDeps([24,1,3,13,15]),import.meta.url)},{path:"/plugin/:id",name:"plugin",component:()=>A(()=>import("./assets/plugin-page-78CA4jh7.js"),__vite__mapDeps([25,26]),import.meta.url)},{path:"/logs",name:"logs",component:()=>A(()=>import("./assets/logger-CJ4vPYnn.js"),__vite__mapDeps([27,6,11]),import.meta.url)},{path:"/activity",name:"activity",component:()=>A(()=>import("./assets/activity-BTPuvvNP.js"),__vite__mapDeps([28,11]),import.meta.url)},{path:"/system",name:"system",component:()=>A(()=>import("./assets/system-Ba_7tip8.js"),__vite__mapDeps([29,2,11]),import.meta.url)},{path:"/tests",name:"tests",component:()=>A(()=>import("./assets/tests-C21pmcDl.js"),__vite__mapDeps([30,8]),import.meta.url)},{path:"/settings",name:"settings",component:()=>A(()=>import("./assets/settings-86u394KL.js"),__vite__mapDeps([31,11]),import.meta.url)},{path:"/settings/environment",name:"settings-environment",component:()=>A(()=>import("./assets/settings-environment-DV741d7r.js"),__vite__mapDeps([32,11]),import.meta.url)},{path:"/settings/registry",name:"settings-registry",component:()=>A(()=>import("./assets/settings-registry-CUu_UwsG.js"),__vite__mapDeps([33,11]),import.meta.url)},{path:"/settings/hub",name:"settings-hub",component:()=>A(()=>import("./assets/settings-hub-y1XekLoM.js"),__vite__mapDeps([34,1,35,11]),import.meta.url)},{path:"/settings/hub/:org/:name",name:"settings-hub-module",component:()=>A(()=>import("./assets/settings-hub-module-CFfP-n46.js"),__vite__mapDeps([36,1,35]),import.meta.url)},{path:"/knowledge",name:"knowledge",component:()=>A(()=>import("./assets/knowledge-B7f2toOe.js"),__vite__mapDeps([37,7,13]),import.meta.url)},{path:"/mcp",name:"mcp",component:()=>A(()=>import("./assets/mcp-xa6ZkHDG.js"),[],import.meta.url)},{path:"/components",name:"components",component:()=>A(()=>import("./assets/components-C4F7M12i.js"),__vite__mapDeps([38,13,15]),import.meta.url)},{path:"/tasks",name:"tasks",component:()=>A(()=>import("./assets/tasks-C61-GdIs.js"),__vite__mapDeps([39,4]),import.meta.url)},{path:"/tasks/:id",name:"task-detail",component:()=>A(()=>import("./assets/task-detail-_SqHbZ-7.js"),__vite__mapDeps([40,1,4,13]),import.meta.url)},{path:"/changes",name:"changes",component:()=>A(()=>import("./assets/changes-CQL3LW9V.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/changes/:id",name:"changes-detail",component:()=>A(()=>import("./assets/changes-CQL3LW9V.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/audit",name:"audit",component:()=>A(()=>import("./assets/audit-CZqtKQmG.js"),[],import.meta.url)},{path:"/:pathMatch(.*)*",name:"not-found",redirect:"/"}];function xi(e,t,n){return Oi(Ti,{initialPath:n,host:e,on:t})}async function Ci(){const e=await window.$W.config(),t=await window.$W.host(),n=await window.$W.api(),o=await window.$W.instance();n.interceptors.response.use(u=>u,u=>(u?.response?.status===401&&t.handleError("auth-expired",{url:u?.config?.url,method:u?.config?.method,message:u?.message}),Promise.reject(u)));let r=null;try{r=await window.$W.on()}catch{}const i=e.context?.route||"/",s=e.theming?.global?.icons??e.theming?.global?.iconSets?.custom;s&&ao({prefix:"custom",icons:s});const l=ho(wi);l.use(io()),l.use(xr),l.provide(Zn,t),l.provide(Jn,n),l.provide(Xn,o),l.provide(Aa,e),r&&l.provide(La,r);const a=xi(t,o.on,i);return l.use(a),l}async function Ai(e="#app"){const t=await Ci();return t.mount(e),t}Ai();export{Yi as A,Qi as B,Ki as C,D,Di as E,Zt as F,Qe as G,Xt as _,Qn as a,Ri as b,Zi as c,Na as d,ts as e,es as f,qi as g,Xi as h,Ji as i,Ea as j,Vi as k,Mi as l,A as m,wt as n,no as o,Hi as p,Bi as q,Ui as r,Be as s,Ln as t,ja as u,Va as v,zi as w,Wi as x,Fi as y,Gi as z};
