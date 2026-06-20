const __vite__mapDeps=(i,m=__vite__mapDeps,d=(m.f||(m.f=["./assets/dashboard-CSK4-BTI.js","./assets/index-BT_m-wrW.js","./assets/pm-Dj_62FpQ.js","./assets/dataflows-Dr2Ef8bh.js","./assets/tasks-CxgCqZXy.js","./assets/changelog-kS_NZw1C.js","./assets/logger-Cq9hvQPy.js","./assets/knowledge-iW30SVUZ.js","./assets/utils-CSjTgnrH.js","./assets/workflow-BnPrisCC.js","./assets/sessions-BrMpENKd.js","./assets/PageHeader.vue_vue_type_script_setup_true_lang-x-0LZxLa.js","./assets/session-detail-CDshxVJR.js","./assets/MarkdownContent-DyBNkW15.js","./assets/DetailPanel.vue_vue_type_script_setup_true_lang-B115sO7W.js","./assets/JsonBlock.vue_vue_type_script_setup_true_lang-D4lkhHol.js","./assets/agents-Pl02yESY.js","./assets/EntryDetailPanel-Dfl-NBLe.js","./assets/models-B3DPFv9Z.js","./assets/tools-page-D8Jt7la8.js","./assets/traits-BW2MPbA7.js","./assets/endpoints-B9BCTqnt.js","./assets/policies-BgLUSNmY.js","./assets/structure-BoeDRm0U.js","./assets/dataflow-detail-CBigbUg1.js","./assets/plugin-page-78CA4jh7.js","./assets/PluginHost-DUK2xtKt.js","./assets/logger-CJ4vPYnn.js","./assets/activity-BTPuvvNP.js","./assets/system-Ba_7tip8.js","./assets/tests-C21pmcDl.js","./assets/settings-86u394KL.js","./assets/settings-environment-DV741d7r.js","./assets/settings-registry-CUu_UwsG.js","./assets/settings-hub-y1XekLoM.js","./assets/RequirementValueInput-CzlAplA9.js","./assets/settings-hub-module-CFfP-n46.js","./assets/knowledge-B7f2toOe.js","./assets/components-C4F7M12i.js","./assets/tasks-C61-GdIs.js","./assets/task-detail-_SqHbZ-7.js","./assets/changes-CQL3LW9V.js"])))=>i.map(i=>d[i]);
import{Icon as X,addCollection as oo}from"@iconify/vue";import{createPinia as ro}from"pinia";import{ref as R,readonly as ao,getCurrentInstance as Xt,onMounted as Ln,nextTick as io,watch as Ne,reactive as so,useId as lo,mergeProps as Z,openBlock as T,createElementBlock as L,createElementVNode as B,renderSlot as He,createTextVNode as Qe,toDisplayString as J,resolveComponent as Ut,resolveDirective as uo,withDirectives as co,createBlock as De,resolveDynamicComponent as po,withCtx as Ze,createCommentVNode as ee,normalizeClass as Re,inject as Ft,defineComponent as Ae,createVNode as j,unref as V,Fragment as Je,renderList as Xe,Teleport as mo,withModifiers as fo,withKeys as en,normalizeStyle as tn,computed as K,onUnmounted as bo,h as Ke,createApp as vo}from"vue";import{useRouter as En,useRoute as go,createMemoryHistory as ho,createRouter as yo,RouterLink as _o}from"vue-router";import{host as $t,on as So,setLocalRouter as ko}from"@wippy-fe/proxy";(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const r of document.querySelectorAll('link[rel="modulepreload"]'))o(r);new MutationObserver(r=>{for(const i of r)if(i.type==="childList")for(const s of i.addedNodes)s.tagName==="LINK"&&s.rel==="modulepreload"&&o(s)}).observe(document,{childList:!0,subtree:!0});function n(r){const i={};return r.integrity&&(i.integrity=r.integrity),r.referrerPolicy&&(i.referrerPolicy=r.referrerPolicy),r.crossOrigin==="use-credentials"?i.credentials="include":r.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function o(r){if(r.ep)return;r.ep=!0;const i=n(r);fetch(r.href,i)}})();var wo=Object.defineProperty,nn=Object.getOwnPropertySymbols,$o=Object.prototype.hasOwnProperty,Po=Object.prototype.propertyIsEnumerable,on=(e,t,n)=>t in e?wo(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,Oo=(e,t)=>{for(var n in t||(t={}))$o.call(t,n)&&on(e,n,t[n]);if(nn)for(var n of nn(t))Po.call(t,n)&&on(e,n,t[n]);return e};function Le(e){return e==null||e===""||Array.isArray(e)&&e.length===0||!(e instanceof Date)&&typeof e=="object"&&Object.keys(e).length===0}function Gt(e){return typeof e=="function"&&"call"in e&&"apply"in e}function I(e){return!Le(e)}function fe(e,t=!0){return e instanceof Object&&e.constructor===Object&&(t||Object.keys(e).length!==0)}function jn(e={},t={}){let n=Oo({},e);return Object.keys(t).forEach(o=>{let r=o;fe(t[r])&&r in e&&fe(e[r])?n[r]=jn(e[r],t[r]):n[r]=t[r]}),n}function To(...e){return e.reduce((t,n,o)=>o===0?n:jn(t,n),{})}function se(e,...t){return Gt(e)?e(...t):e}function te(e,t=!0){return typeof e=="string"&&(t||e!=="")}function me(e){return te(e)?e.replace(/(-|_)/g,"").toLowerCase():e}function Yt(e,t="",n={}){let o=me(t).split("."),r=o.shift();if(r){if(fe(e)){let i=Object.keys(e).find(s=>me(s)===r)||"";return Yt(se(e[i],n),o.join("."),n)}return}return se(e,n)}function Nn(e,t=!0){return Array.isArray(e)&&(t||e.length!==0)}function xo(e){return I(e)&&!isNaN(e)}function xe(e,t){if(t){let n=t.test(e);return t.lastIndex=0,n}return!1}function Co(...e){return To(...e)}function Ge(e){return e&&e.replace(/\/\*(?:(?!\*\/)[\s\S])*\*\/|[\r\n\t]+/g,"").replace(/ {2,}/g," ").replace(/ ([{:}]) /g,"$1").replace(/([;,]) /g,"$1").replace(/ !/g,"!").replace(/: /g,":").trim()}function Ao(e){return te(e,!1)?e[0].toUpperCase()+e.slice(1):e}function In(e){return te(e)?e.replace(/(_)/g,"-").replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase():e}function Dn(){let e=new Map;return{on(t,n){let o=e.get(t);return o?o.push(n):o=[n],e.set(t,o),this},off(t,n){let o=e.get(t);return o&&o.splice(o.indexOf(n)>>>0,1),this},emit(t,n){let o=e.get(t);o&&o.forEach(r=>{r(n)})},clear(){e.clear()}}}function Ye(...e){if(e){let t=[];for(let n=0;n<e.length;n++){let o=e[n];if(!o)continue;let r=typeof o;if(r==="string"||r==="number")t.push(o);else if(r==="object"){let i=Array.isArray(o)?[Ye(...o)]:Object.entries(o).map(([s,l])=>l?s:void 0);t=i.length?t.concat(i.filter(s=>!!s)):t}}return t.join(" ").trim()}}function Lo(e,t){return e?e.classList?e.classList.contains(t):new RegExp("(^| )"+t+"( |$)","gi").test(e.className):!1}function Eo(e,t){if(e&&t){let n=o=>{Lo(e,o)||(e.classList?e.classList.add(o):e.className+=" "+o)};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function Dt(e,t){if(e&&t){let n=o=>{e.classList?e.classList.remove(o):e.className=e.className.replace(new RegExp("(^|\\b)"+o.split(" ").join("|")+"(\\b|$)","gi")," ")};[t].flat().filter(Boolean).forEach(o=>o.split(" ").forEach(n))}}function rn(e){return e?Math.abs(e.scrollLeft):0}function jo(e,t){return e instanceof HTMLElement?e.offsetWidth:0}function No(e){if(e){let t=e.parentNode;return t&&t instanceof ShadowRoot&&t.host&&(t=t.host),t}return null}function Io(e){return!!(e!==null&&typeof e<"u"&&e.nodeName&&No(e))}function mt(e){return typeof Element<"u"?e instanceof Element:e!==null&&typeof e=="object"&&e.nodeType===1&&typeof e.nodeName=="string"}function Pt(e,t={}){if(mt(e)){let n=(o,r)=>{var i,s;let l=(i=e?.$attrs)!=null&&i[o]?[(s=e?.$attrs)==null?void 0:s[o]]:[];return[r].flat().reduce((a,u)=>{if(u!=null){let d=typeof u;if(d==="string"||d==="number")a.push(u);else if(d==="object"){let c=Array.isArray(u)?n(o,u):Object.entries(u).map(([p,m])=>o==="style"&&(m||m===0)?`${p.replace(/([a-z])([A-Z])/g,"$1-$2").toLowerCase()}:${m}`:m?p:void 0);a=c.length?a.concat(c.filter(p=>!!p)):a}}return a},l)};Object.entries(t).forEach(([o,r])=>{if(r!=null){let i=o.match(/^on(.+)/);i?e.addEventListener(i[1].toLowerCase(),r):o==="p-bind"||o==="pBind"?Pt(e,r):(r=o==="class"?[...new Set(n("class",r))].join(" ").trim():o==="style"?n("style",r).join(";").trim():r,(e.$attrs=e.$attrs||{})&&(e.$attrs[o]=r),e.setAttribute(o,r))}})}}function Do(e,t={},...n){{let o=document.createElement(e);return Pt(o,t),o.append(...n),o}}function Ro(e,t){return mt(e)?e.matches(t)?e:e.querySelector(t):null}function Vo(e,t){if(mt(e)){let n=e.getAttribute(t);return isNaN(n)?n==="true"||n==="false"?n==="true":n:+n}}function an(e){if(e){let t=e.offsetHeight,n=getComputedStyle(e);return t-=parseFloat(n.paddingTop)+parseFloat(n.paddingBottom)+parseFloat(n.borderTopWidth)+parseFloat(n.borderBottomWidth),t}return 0}function Mo(e){if(e){let t=e.getBoundingClientRect();return{top:t.top+(window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0),left:t.left+(window.pageXOffset||rn(document.documentElement)||rn(document.body)||0)}}return{top:"auto",left:"auto"}}function Bo(e,t){return e?e.offsetHeight:0}function sn(e){if(e){let t=e.offsetWidth,n=getComputedStyle(e);return t-=parseFloat(n.paddingLeft)+parseFloat(n.paddingRight)+parseFloat(n.borderLeftWidth)+parseFloat(n.borderRightWidth),t}return 0}function Uo(){return!!(typeof window<"u"&&window.document&&window.document.createElement)}function zo(e,t="",n){mt(e)&&n!==null&&n!==void 0&&e.setAttribute(t,n)}var ht={};function Wo(e="pui_id_"){return Object.hasOwn(ht,e)||(ht[e]=0),ht[e]++,`${e}${ht[e]}`}var qo=Object.defineProperty,Ho=Object.defineProperties,Ko=Object.getOwnPropertyDescriptors,Ot=Object.getOwnPropertySymbols,Rn=Object.prototype.hasOwnProperty,Vn=Object.prototype.propertyIsEnumerable,ln=(e,t,n)=>t in e?qo(e,t,{enumerable:!0,configurable:!0,writable:!0,value:n}):e[t]=n,ce=(e,t)=>{for(var n in t||(t={}))Rn.call(t,n)&&ln(e,n,t[n]);if(Ot)for(var n of Ot(t))Vn.call(t,n)&&ln(e,n,t[n]);return e},Rt=(e,t)=>Ho(e,Ko(t)),he=(e,t)=>{var n={};for(var o in e)Rn.call(e,o)&&t.indexOf(o)<0&&(n[o]=e[o]);if(e!=null&&Ot)for(var o of Ot(e))t.indexOf(o)<0&&Vn.call(e,o)&&(n[o]=e[o]);return n},Fo=Dn(),z=Fo,et=/{([^}]*)}/g,Mn=/(\d+\s+[\+\-\*\/]\s+\d+)/g,Bn=/var\([^)]+\)/g;function un(e){return te(e)?e.replace(/[A-Z]/g,(t,n)=>n===0?t:"."+t.toLowerCase()).toLowerCase():e}function Go(e){return fe(e)&&e.hasOwnProperty("$value")&&e.hasOwnProperty("$type")?e.$value:e}function Yo(e){return e.replaceAll(/ /g,"").replace(/[^\w]/g,"-")}function zt(e="",t=""){return Yo(`${te(e,!1)&&te(t,!1)?`${e}-`:e}${t}`)}function Un(e="",t=""){return`--${zt(e,t)}`}function Qo(e=""){let t=(e.match(/{/g)||[]).length,n=(e.match(/}/g)||[]).length;return(t+n)%2!==0}function zn(e,t="",n="",o=[],r){if(te(e)){let i=e.trim();if(Qo(i))return;if(xe(i,et)){let s=i.replaceAll(et,l=>{let a=l.replace(/{|}/g,"").split(".").filter(u=>!o.some(d=>xe(u,d)));return`var(${Un(n,In(a.join("-")))}${I(r)?`, ${r}`:""})`});return xe(s.replace(Bn,"0"),Mn)?`calc(${s})`:s}return i}else if(xo(e))return e}function Zo(e,t,n){te(t,!1)&&e.push(`${t}:${n};`)}function je(e,t){return e?`${e}{${t}}`:""}function Wn(e,t){if(e.indexOf("dt(")===-1)return e;function n(s,l){let a=[],u=0,d="",c=null,p=0;for(;u<=s.length;){let m=s[u];if((m==='"'||m==="'"||m==="`")&&s[u-1]!=="\\"&&(c=c===m?null:m),!c&&(m==="("&&p++,m===")"&&p--,(m===","||u===s.length)&&p===0)){let b=d.trim();b.startsWith("dt(")?a.push(Wn(b,l)):a.push(o(b)),d="",u++;continue}m!==void 0&&(d+=m),u++}return a}function o(s){let l=s[0];if((l==='"'||l==="'"||l==="`")&&s[s.length-1]===l)return s.slice(1,-1);let a=Number(s);return isNaN(a)?s:a}let r=[],i=[];for(let s=0;s<e.length;s++)if(e[s]==="d"&&e.slice(s,s+3)==="dt(")i.push(s),s+=2;else if(e[s]===")"&&i.length>0){let l=i.pop();i.length===0&&r.push([l,s])}if(!r.length)return e;for(let s=r.length-1;s>=0;s--){let[l,a]=r[s],u=e.slice(l+3,a),d=n(u,t),c=t(...d);e=e.slice(0,l)+c+e.slice(a+1)}return e}var Ce=(...e)=>Jo(E.getTheme(),...e),Jo=(e={},t,n,o)=>{if(t){let{variable:r,options:i}=E.defaults||{},{prefix:s,transform:l}=e?.options||i||{},a=xe(t,et)?t:`{${t}}`;return o==="value"||Le(o)&&l==="strict"?E.getTokenValue(t):zn(a,void 0,s,[r.excludedKeyRegex],n)}return""};function yt(e,...t){if(e instanceof Array){let n=e.reduce((o,r,i)=>{var s;return o+r+((s=se(t[i],{dt:Ce}))!=null?s:"")},"");return Wn(n,Ce)}return se(e,{dt:Ce})}function Xo(e,t={}){let n=E.defaults.variable,{prefix:o=n.prefix,selector:r=n.selector,excludedKeyRegex:i=n.excludedKeyRegex}=t,s=[],l=[],a=[{node:e,path:o}];for(;a.length;){let{node:d,path:c}=a.pop();for(let p in d){let m=d[p],b=Go(m),_=xe(p,i)?zt(c):zt(c,In(p));if(fe(b))a.push({node:b,path:_});else{let h=Un(_),S=zn(b,_,o,[i]);Zo(l,h,S);let O=_;o&&O.startsWith(o+"-")&&(O=O.slice(o.length+1)),s.push(O.replace(/-/g,"."))}}}let u=l.join("");return{value:l,tokens:s,declarations:u,css:je(r,u)}}var de={regex:{rules:{class:{pattern:/^\.([a-zA-Z][\w-]*)$/,resolve(e){return{type:"class",selector:e,matched:this.pattern.test(e.trim())}}},attr:{pattern:/^\[(.*)\]$/,resolve(e){return{type:"attr",selector:`:root${e},:host${e}`,matched:this.pattern.test(e.trim())}}},media:{pattern:/^@media (.*)$/,resolve(e){return{type:"media",selector:e,matched:this.pattern.test(e.trim())}}},system:{pattern:/^system$/,resolve(e){return{type:"system",selector:"@media (prefers-color-scheme: dark)",matched:this.pattern.test(e.trim())}}},custom:{resolve(e){return{type:"custom",selector:e,matched:!0}}}},resolve(e){let t=Object.keys(this.rules).filter(n=>n!=="custom").map(n=>this.rules[n]);return[e].flat().map(n=>{var o;return(o=t.map(r=>r.resolve(n)).find(r=>r.matched))!=null?o:this.rules.custom.resolve(n)})}},_toVariables(e,t){return Xo(e,{prefix:t?.prefix})},getCommon({name:e="",theme:t={},params:n,set:o,defaults:r}){var i,s,l,a,u,d,c;let{preset:p,options:m}=t,b,_,h,S,O,C,v;if(I(p)&&m.transform!=="strict"){let{primitive:k,semantic:M,extend:q}=p,le=M||{},{colorScheme:F}=le,ne=he(le,["colorScheme"]),G=q||{},{colorScheme:oe}=G,re=he(G,["colorScheme"]),H=F||{},{dark:be}=H,ye=he(H,["dark"]),ve=oe||{},{dark:_e}=ve,Se=he(ve,["dark"]),N=I(k)?this._toVariables({primitive:k},m):{},ue=I(ne)?this._toVariables({semantic:ne},m):{},ge=I(ye)?this._toVariables({light:ye},m):{},Ee=I(be)?this._toVariables({dark:be},m):{},ke=I(re)?this._toVariables({semantic:re},m):{},ft=I(Se)?this._toVariables({light:Se},m):{},Me=I(_e)?this._toVariables({dark:_e},m):{},[Be,xt]=[(i=N.declarations)!=null?i:"",N.tokens],[Oe,Ct]=[(s=ue.declarations)!=null?s:"",ue.tokens||[]],[bt,At]=[(l=ge.declarations)!=null?l:"",ge.tokens||[]],[Lt,we]=[(a=Ee.declarations)!=null?a:"",Ee.tokens||[]],[Te,ae]=[(u=ke.declarations)!=null?u:"",ke.tokens||[]],[Ue,ze]=[(d=ft.declarations)!=null?d:"",ft.tokens||[]],[Et,vt]=[(c=Me.declarations)!=null?c:"",Me.tokens||[]];b=this.transformCSS(e,Be,"light","variable",m,o,r),_=xt;let jt=this.transformCSS(e,`${Oe}${bt}`,"light","variable",m,o,r),Nt=this.transformCSS(e,`${Lt}`,"dark","variable",m,o,r);h=`${jt}${Nt}`,S=[...new Set([...Ct,...At,...we])];let It=this.transformCSS(e,`${Te}${Ue}color-scheme:light`,"light","variable",m,o,r),gt=this.transformCSS(e,`${Et}color-scheme:dark`,"dark","variable",m,o,r);O=`${It}${gt}`,C=[...new Set([...ae,...ze,...vt])],v=se(p.css,{dt:Ce})}return{primitive:{css:b,tokens:_},semantic:{css:h,tokens:S},global:{css:O,tokens:C},style:v}},getPreset({name:e="",preset:t={},options:n,params:o,set:r,defaults:i,selector:s}){var l,a,u;let d,c,p;if(I(t)&&n.transform!=="strict"){let m=e.replace("-directive",""),b=t,{colorScheme:_,extend:h,css:S}=b,O=he(b,["colorScheme","extend","css"]),C=h||{},{colorScheme:v}=C,k=he(C,["colorScheme"]),M=_||{},{dark:q}=M,le=he(M,["dark"]),F=v||{},{dark:ne}=F,G=he(F,["dark"]),oe=I(O)?this._toVariables({[m]:ce(ce({},O),k)},n):{},re=I(le)?this._toVariables({[m]:ce(ce({},le),G)},n):{},H=I(q)?this._toVariables({[m]:ce(ce({},q),ne)},n):{},[be,ye]=[(l=oe.declarations)!=null?l:"",oe.tokens||[]],[ve,_e]=[(a=re.declarations)!=null?a:"",re.tokens||[]],[Se,N]=[(u=H.declarations)!=null?u:"",H.tokens||[]],ue=this.transformCSS(m,`${be}${ve}`,"light","variable",n,r,i,s),ge=this.transformCSS(m,Se,"dark","variable",n,r,i,s);d=`${ue}${ge}`,c=[...new Set([...ye,..._e,...N])],p=se(S,{dt:Ce})}return{css:d,tokens:c,style:p}},getPresetC({name:e="",theme:t={},params:n,set:o,defaults:r}){var i;let{preset:s,options:l}=t,a=(i=s?.components)==null?void 0:i[e];return this.getPreset({name:e,preset:a,options:l,params:n,set:o,defaults:r})},getPresetD({name:e="",theme:t={},params:n,set:o,defaults:r}){var i,s;let l=e.replace("-directive",""),{preset:a,options:u}=t,d=((i=a?.components)==null?void 0:i[l])||((s=a?.directives)==null?void 0:s[l]);return this.getPreset({name:l,preset:d,options:u,params:n,set:o,defaults:r})},applyDarkColorScheme(e){return!(e.darkModeSelector==="none"||e.darkModeSelector===!1)},getColorSchemeOption(e,t){var n;return this.applyDarkColorScheme(e)?this.regex.resolve(e.darkModeSelector===!0?t.options.darkModeSelector:(n=e.darkModeSelector)!=null?n:t.options.darkModeSelector):[]},getLayerOrder(e,t={},n,o){let{cssLayer:r}=t;return r?`@layer ${se(r.order||r.name||"primeui",n)}`:""},getCommonStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:i}){let s=this.getCommon({name:e,theme:t,params:n,set:r,defaults:i}),l=Object.entries(o).reduce((a,[u,d])=>a.push(`${u}="${d}"`)&&a,[]).join(" ");return Object.entries(s||{}).reduce((a,[u,d])=>{if(fe(d)&&Object.hasOwn(d,"css")){let c=Ge(d.css),p=`${u}-variables`;a.push(`<style type="text/css" data-primevue-style-id="${p}" ${l}>${c}</style>`)}return a},[]).join("")},getStyleSheet({name:e="",theme:t={},params:n,props:o={},set:r,defaults:i}){var s;let l={name:e,theme:t,params:n,set:r,defaults:i},a=(s=e.includes("-directive")?this.getPresetD(l):this.getPresetC(l))==null?void 0:s.css,u=Object.entries(o).reduce((d,[c,p])=>d.push(`${c}="${p}"`)&&d,[]).join(" ");return a?`<style type="text/css" data-primevue-style-id="${e}-variables" ${u}>${Ge(a)}</style>`:""},createTokens(e={},t,n="",o="",r={}){let i=function(l,a={},u=[]){if(u.includes(this.path))return console.warn(`Circular reference detected at ${this.path}`),{colorScheme:l,path:this.path,paths:a,value:void 0};u.push(this.path),a.name=this.path,a.binding||(a.binding={});let d=this.value;if(typeof this.value=="string"&&et.test(this.value)){let c=this.value.trim().replace(et,p=>{var m;let b=p.slice(1,-1),_=this.tokens[b];if(!_)return console.warn(`Token not found for path: ${b}`),"__UNRESOLVED__";let h=_.computed(l,a,u);return Array.isArray(h)&&h.length===2?`light-dark(${h[0].value},${h[1].value})`:(m=h?.value)!=null?m:"__UNRESOLVED__"});d=Mn.test(c.replace(Bn,"0"))?`calc(${c})`:c}return Le(a.binding)&&delete a.binding,u.pop(),{colorScheme:l,path:this.path,paths:a,value:d.includes("__UNRESOLVED__")?void 0:d}},s=(l,a,u)=>{Object.entries(l).forEach(([d,c])=>{let p=xe(d,t.variable.excludedKeyRegex)?a:a?`${a}.${un(d)}`:un(d),m=u?`${u}.${d}`:d;fe(c)?s(c,p,m):(r[p]||(r[p]={paths:[],computed:(b,_={},h=[])=>{if(r[p].paths.length===1)return r[p].paths[0].computed(r[p].paths[0].scheme,_.binding,h);if(b&&b!=="none")for(let S=0;S<r[p].paths.length;S++){let O=r[p].paths[S];if(O.scheme===b)return O.computed(b,_.binding,h)}return r[p].paths.map(S=>S.computed(S.scheme,_[S.scheme],h))}}),r[p].paths.push({path:m,value:c,scheme:m.includes("colorScheme.light")?"light":m.includes("colorScheme.dark")?"dark":"none",computed:i,tokens:r}))})};return s(e,n,o),r},getTokenValue(e,t,n){var o;let r=(l=>l.split(".").filter(a=>!xe(a.toLowerCase(),n.variable.excludedKeyRegex)).join("."))(t),i=t.includes("colorScheme.light")?"light":t.includes("colorScheme.dark")?"dark":void 0,s=[(o=e[r])==null?void 0:o.computed(i)].flat().filter(l=>l);return s.length===1?s[0].value:s.reduce((l={},a)=>{let u=a,{colorScheme:d}=u,c=he(u,["colorScheme"]);return l[d]=c,l},void 0)},getSelectorRule(e,t,n,o){return n==="class"||n==="attr"?je(I(t)?`${e}${t},${e} ${t}`:e,o):je(e,je(t??":root,:host",o))},transformCSS(e,t,n,o,r={},i,s,l){if(I(t)){let{cssLayer:a}=r;if(o!=="style"){let u=this.getColorSchemeOption(r,s);t=n==="dark"?u.reduce((d,{type:c,selector:p})=>(I(p)&&(d+=p.includes("[CSS]")?p.replace("[CSS]",t):this.getSelectorRule(p,l,c,t)),d),""):je(l??":root,:host",t)}if(a){let u={name:"primeui"};fe(a)&&(u.name=se(a.name,{name:e,type:o})),I(u.name)&&(t=je(`@layer ${u.name}`,t),i?.layerNames(u.name))}return t}return""}},E={defaults:{variable:{prefix:"p",selector:":root,:host",excludedKeyRegex:/^(primitive|semantic|components|directives|variables|colorscheme|light|dark|common|root|states|extend|css)$/gi},options:{prefix:"p",darkModeSelector:"system",cssLayer:!1}},_theme:void 0,_layerNames:new Set,_loadedStyleNames:new Set,_loadingStyles:new Set,_tokens:{},update(e={}){let{theme:t}=e;t&&(this._theme=Rt(ce({},t),{options:ce(ce({},this.defaults.options),t.options)}),this._tokens=de.createTokens(this.preset,this.defaults),this.clearLoadedStyleNames())},get theme(){return this._theme},get preset(){var e;return((e=this.theme)==null?void 0:e.preset)||{}},get options(){var e;return((e=this.theme)==null?void 0:e.options)||{}},get tokens(){return this._tokens},getTheme(){return this.theme},setTheme(e){this.update({theme:e}),z.emit("theme:change",e)},getPreset(){return this.preset},setPreset(e){this._theme=Rt(ce({},this.theme),{preset:e}),this._tokens=de.createTokens(e,this.defaults),this.clearLoadedStyleNames(),z.emit("preset:change",e),z.emit("theme:change",this.theme)},getOptions(){return this.options},setOptions(e){this._theme=Rt(ce({},this.theme),{options:e}),this.clearLoadedStyleNames(),z.emit("options:change",e),z.emit("theme:change",this.theme)},getLayerNames(){return[...this._layerNames]},setLayerNames(e){this._layerNames.add(e)},getLoadedStyleNames(){return this._loadedStyleNames},isStyleNameLoaded(e){return this._loadedStyleNames.has(e)},setLoadedStyleName(e){this._loadedStyleNames.add(e)},deleteLoadedStyleName(e){this._loadedStyleNames.delete(e)},clearLoadedStyleNames(){this._loadedStyleNames.clear()},getTokenValue(e){return de.getTokenValue(this.tokens,e,this.defaults)},getCommon(e="",t){return de.getCommon({name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getComponent(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return de.getPresetC(n)},getDirective(e="",t){let n={name:e,theme:this.theme,params:t,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return de.getPresetD(n)},getCustomPreset(e="",t,n,o){let r={name:e,preset:t,options:this.options,selector:n,params:o,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}};return de.getPreset(r)},getLayerOrderCSS(e=""){return de.getLayerOrder(e,this.options,{names:this.getLayerNames()},this.defaults)},transformCSS(e="",t,n="style",o){return de.transformCSS(e,t,o,n,this.options,{layerNames:this.setLayerNames.bind(this)},this.defaults)},getCommonStyleSheet(e="",t,n={}){return de.getCommonStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},getStyleSheet(e,t,n={}){return de.getStyleSheet({name:e,theme:this.theme,params:t,props:n,defaults:this.defaults,set:{layerNames:this.setLayerNames.bind(this)}})},onStyleMounted(e){this._loadingStyles.add(e)},onStyleUpdated(e){this._loadingStyles.add(e)},onStyleLoaded(e,{name:t}){this._loadingStyles.size&&(this._loadingStyles.delete(t),z.emit(`theme:${t}:load`,e),!this._loadingStyles.size&&z.emit("theme:load"))}},W={STARTS_WITH:"startsWith",CONTAINS:"contains",NOT_CONTAINS:"notContains",ENDS_WITH:"endsWith",EQUALS:"equals",NOT_EQUALS:"notEquals",LESS_THAN:"lt",LESS_THAN_OR_EQUAL_TO:"lte",GREATER_THAN:"gt",GREATER_THAN_OR_EQUAL_TO:"gte",DATE_IS:"dateIs",DATE_IS_NOT:"dateIsNot",DATE_BEFORE:"dateBefore",DATE_AFTER:"dateAfter"},er=`
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
`;function tt(e){"@babel/helpers - typeof";return tt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},tt(e)}function dn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function cn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?dn(Object(n),!0).forEach(function(o){tr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):dn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function tr(e,t,n){return(t=nr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function nr(e){var t=or(e,"string");return tt(t)=="symbol"?t:t+""}function or(e,t){if(tt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(tt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function rr(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0;Xt()&&Xt().components?Ln(e):t?e():io(e)}var ar=0;function ir(e){var t=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},n=R(!1),o=R(e),r=R(null),i=Uo()?window.document:void 0,s=t.document,l=s===void 0?i:s,a=t.immediate,u=a===void 0?!0:a,d=t.manual,c=d===void 0?!1:d,p=t.name,m=p===void 0?"style_".concat(++ar):p,b=t.id,_=b===void 0?void 0:b,h=t.media,S=h===void 0?void 0:h,O=t.nonce,C=O===void 0?void 0:O,v=t.first,k=v===void 0?!1:v,M=t.onMounted,q=M===void 0?void 0:M,le=t.onUpdated,F=le===void 0?void 0:le,ne=t.onLoad,G=ne===void 0?void 0:ne,oe=t.props,re=oe===void 0?{}:oe,H=function(){},be=function(_e){var Se=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(l){var N=cn(cn({},re),Se),ue=N.name||m,ge=N.id||_,Ee=N.nonce||C;r.value=l.querySelector('style[data-primevue-style-id="'.concat(ue,'"]'))||l.getElementById(ge)||l.createElement("style"),r.value.isConnected||(o.value=_e||e,Pt(r.value,{type:"text/css",id:ge,media:S,nonce:Ee}),k?l.head.prepend(r.value):l.head.appendChild(r.value),zo(r.value,"data-primevue-style-id",ue),Pt(r.value,N),r.value.onload=function(ke){return G?.(ke,{name:ue})},q?.(ue)),!n.value&&(H=Ne(o,function(ke){r.value.textContent=ke,F?.(ue)},{immediate:!0}),n.value=!0)}},ye=function(){!l||!n.value||(H(),Io(r.value)&&l.head.removeChild(r.value),n.value=!1,r.value=null)};return u&&!c&&rr(be),{id:_,name:m,el:r,css:o,unload:ye,load:be,isLoaded:ao(n)}}function nt(e){"@babel/helpers - typeof";return nt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},nt(e)}var pn,mn,fn,bn;function vn(e,t){return dr(e)||ur(e,t)||lr(e,t)||sr()}function sr(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function lr(e,t){if(e){if(typeof e=="string")return gn(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?gn(e,t):void 0}}function gn(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function ur(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t!==0)for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function dr(e){if(Array.isArray(e))return e}function hn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function Vt(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?hn(Object(n),!0).forEach(function(o){cr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):hn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function cr(e,t,n){return(t=pr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function pr(e){var t=mr(e,"string");return nt(t)=="symbol"?t:t+""}function mr(e,t){if(nt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(nt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}function _t(e,t){return t||(t=e.slice(0)),Object.freeze(Object.defineProperties(e,{raw:{value:Object.freeze(t)}}))}var fr=function(t){var n=t.dt;return`
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
`)},br={},vr={},D={name:"base",css:fr,style:er,classes:br,inlineStyles:vr,load:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:function(i){return i},r=o(yt(pn||(pn=_t(["",""])),t));return I(r)?ir(Ge(r),Vt({name:this.name},n)):{}},loadCSS:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};return this.load(this.css,t)},loadStyle:function(){var t=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"";return this.load(this.style,n,function(){var r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"";return E.transformCSS(n.name||t.name,"".concat(r).concat(yt(mn||(mn=_t(["",""])),o)))})},getCommonTheme:function(t){return E.getCommon(this.name,t)},getComponentTheme:function(t){return E.getComponent(this.name,t)},getDirectiveTheme:function(t){return E.getDirective(this.name,t)},getPresetTheme:function(t,n,o){return E.getCustomPreset(this.name,t,n,o)},getLayerOrderThemeCSS:function(){return E.getLayerOrderCSS(this.name)},getStyleSheet:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};if(this.css){var o=se(this.css,{dt:Ce})||"",r=Ge(yt(fn||(fn=_t(["","",""])),o,t)),i=Object.entries(n).reduce(function(s,l){var a=vn(l,2),u=a[0],d=a[1];return s.push("".concat(u,'="').concat(d,'"'))&&s},[]).join(" ");return I(r)?'<style type="text/css" data-primevue-style-id="'.concat(this.name,'" ').concat(i,">").concat(r,"</style>"):""}return""},getCommonThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return E.getCommonStyleSheet(this.name,t,n)},getThemeStyleSheet:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=[E.getStyleSheet(this.name,t,n)];if(this.style){var r=this.name==="base"?"global-style":"".concat(this.name,"-style"),i=yt(bn||(bn=_t(["",""])),se(this.style,{dt:Ce})),s=Ge(E.transformCSS(r,i)),l=Object.entries(n).reduce(function(a,u){var d=vn(u,2),c=d[0],p=d[1];return a.push("".concat(c,'="').concat(p,'"'))&&a},[]).join(" ");I(s)&&o.push('<style type="text/css" data-primevue-style-id="'.concat(r,'" ').concat(l,">").concat(s,"</style>"))}return o.join("")},extend:function(t){return Vt(Vt({},this),{},{css:void 0,style:void 0},t)}},Pe=Dn();function ot(e){"@babel/helpers - typeof";return ot=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ot(e)}function yn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function St(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?yn(Object(n),!0).forEach(function(o){gr(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):yn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function gr(e,t,n){return(t=hr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function hr(e){var t=yr(e,"string");return ot(t)=="symbol"?t:t+""}function yr(e,t){if(ot(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ot(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var _r={ripple:!1,inputStyle:null,inputVariant:null,locale:{startsWith:"Starts with",contains:"Contains",notContains:"Not contains",endsWith:"Ends with",equals:"Equals",notEquals:"Not equals",noFilter:"No Filter",lt:"Less than",lte:"Less than or equal to",gt:"Greater than",gte:"Greater than or equal to",dateIs:"Date is",dateIsNot:"Date is not",dateBefore:"Date is before",dateAfter:"Date is after",clear:"Clear",apply:"Apply",matchAll:"Match All",matchAny:"Match Any",addRule:"Add Rule",removeRule:"Remove Rule",accept:"Yes",reject:"No",choose:"Choose",upload:"Upload",cancel:"Cancel",completed:"Completed",pending:"Pending",fileSizeTypes:["B","KB","MB","GB","TB","PB","EB","ZB","YB"],dayNames:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],dayNamesShort:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],dayNamesMin:["Su","Mo","Tu","We","Th","Fr","Sa"],monthNames:["January","February","March","April","May","June","July","August","September","October","November","December"],monthNamesShort:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],chooseYear:"Choose Year",chooseMonth:"Choose Month",chooseDate:"Choose Date",prevDecade:"Previous Decade",nextDecade:"Next Decade",prevYear:"Previous Year",nextYear:"Next Year",prevMonth:"Previous Month",nextMonth:"Next Month",prevHour:"Previous Hour",nextHour:"Next Hour",prevMinute:"Previous Minute",nextMinute:"Next Minute",prevSecond:"Previous Second",nextSecond:"Next Second",am:"am",pm:"pm",today:"Today",weekHeader:"Wk",firstDayOfWeek:0,showMonthAfterYear:!1,dateFormat:"mm/dd/yy",weak:"Weak",medium:"Medium",strong:"Strong",passwordPrompt:"Enter a password",emptyFilterMessage:"No results found",searchMessage:"{0} results are available",selectionMessage:"{0} items selected",emptySelectionMessage:"No selected item",emptySearchMessage:"No results found",fileChosenMessage:"{0} files",noFileChosenMessage:"No file chosen",emptyMessage:"No available options",aria:{trueLabel:"True",falseLabel:"False",nullLabel:"Not Selected",star:"1 star",stars:"{star} stars",selectAll:"All items selected",unselectAll:"All items unselected",close:"Close",previous:"Previous",next:"Next",navigation:"Navigation",scrollTop:"Scroll Top",moveTop:"Move Top",moveUp:"Move Up",moveDown:"Move Down",moveBottom:"Move Bottom",moveToTarget:"Move to Target",moveToSource:"Move to Source",moveAllToTarget:"Move All to Target",moveAllToSource:"Move All to Source",pageLabel:"Page {page}",firstPageLabel:"First Page",lastPageLabel:"Last Page",nextPageLabel:"Next Page",prevPageLabel:"Previous Page",rowsPerPageLabel:"Rows per page",jumpToPageDropdownLabel:"Jump to Page Dropdown",jumpToPageInputLabel:"Jump to Page Input",selectRow:"Row Selected",unselectRow:"Row Unselected",expandRow:"Row Expanded",collapseRow:"Row Collapsed",showFilterMenu:"Show Filter Menu",hideFilterMenu:"Hide Filter Menu",filterOperator:"Filter Operator",filterConstraint:"Filter Constraint",editRow:"Row Edit",saveEdit:"Save Edit",cancelEdit:"Cancel Edit",listView:"List View",gridView:"Grid View",slide:"Slide",slideNumber:"{slideNumber}",zoomImage:"Zoom Image",zoomIn:"Zoom In",zoomOut:"Zoom Out",rotateRight:"Rotate Right",rotateLeft:"Rotate Left",listLabel:"Option List"}},filterMatchModeOptions:{text:[W.STARTS_WITH,W.CONTAINS,W.NOT_CONTAINS,W.ENDS_WITH,W.EQUALS,W.NOT_EQUALS],numeric:[W.EQUALS,W.NOT_EQUALS,W.LESS_THAN,W.LESS_THAN_OR_EQUAL_TO,W.GREATER_THAN,W.GREATER_THAN_OR_EQUAL_TO],date:[W.DATE_IS,W.DATE_IS_NOT,W.DATE_BEFORE,W.DATE_AFTER]},zIndex:{modal:1100,overlay:1e3,menu:1e3,tooltip:1100},theme:void 0,unstyled:!1,pt:void 0,ptOptions:{mergeSections:!0,mergeProps:!1},csp:{nonce:void 0}},Sr=Symbol();function kr(e,t){var n={config:so(t)};return e.config.globalProperties.$primevue=n,e.provide(Sr,n),wr(),$r(e,n),n}var Ie=[];function wr(){z.clear(),Ie.forEach(function(e){return e?.()}),Ie=[]}function $r(e,t){var n=R(!1),o=function(){var u;if(((u=t.config)===null||u===void 0?void 0:u.theme)!=="none"&&!E.isStyleNameLoaded("common")){var d,c,p=((d=D.getCommonTheme)===null||d===void 0?void 0:d.call(D))||{},m=p.primitive,b=p.semantic,_=p.global,h=p.style,S={nonce:(c=t.config)===null||c===void 0||(c=c.csp)===null||c===void 0?void 0:c.nonce};D.load(m?.css,St({name:"primitive-variables"},S)),D.load(b?.css,St({name:"semantic-variables"},S)),D.load(_?.css,St({name:"global-variables"},S)),D.loadStyle(St({name:"global-style"},S),h),E.setLoadedStyleName("common")}};z.on("theme:change",function(a){n.value||(e.config.globalProperties.$primevue.config.theme=a,n.value=!0)});var r=Ne(t.config,function(a,u){Pe.emit("config:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0}),i=Ne(function(){return t.config.ripple},function(a,u){Pe.emit("config:ripple:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0}),s=Ne(function(){return t.config.theme},function(a,u){n.value||E.setTheme(a),t.config.unstyled||o(),n.value=!1,Pe.emit("config:theme:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!1}),l=Ne(function(){return t.config.unstyled},function(a,u){!a&&t.config.theme&&o(),Pe.emit("config:unstyled:change",{newValue:a,oldValue:u})},{immediate:!0,deep:!0});Ie.push(r),Ie.push(i),Ie.push(s),Ie.push(l)}var Pr={install:function(t,n){var o=Co(_r,n);kr(t,o)}};const Or={install:e=>e.use(Pr,{theme:"none"})};var $e={_loadedStyleNames:new Set,getLoadedStyleNames:function(){return this._loadedStyleNames},isStyleNameLoaded:function(t){return this._loadedStyleNames.has(t)},setLoadedStyleName:function(t){this._loadedStyleNames.add(t)},deleteLoadedStyleName:function(t){this._loadedStyleNames.delete(t)},clearLoadedStyleNames:function(){this._loadedStyleNames.clear()}};function Tr(){var e=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"pc",t=lo();return"".concat(e).concat(t.replace("v-","").replaceAll("-","_"))}var _n=D.extend({name:"common"});function rt(e){"@babel/helpers - typeof";return rt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},rt(e)}function xr(e){return Kn(e)||Cr(e)||Hn(e)||qn()}function Cr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function We(e,t){return Kn(e)||Ar(e,t)||Hn(e,t)||qn()}function qn(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Hn(e,t){if(e){if(typeof e=="string")return Wt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Wt(e,t):void 0}}function Wt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function Ar(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t===0){if(Object(n)!==n)return;a=!1}else for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function Kn(e){if(Array.isArray(e))return e}function Sn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function P(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Sn(Object(n),!0).forEach(function(o){Fe(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Sn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Fe(e,t,n){return(t=Lr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Lr(e){var t=Er(e,"string");return rt(t)=="symbol"?t:t+""}function Er(e,t){if(rt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(rt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Qt={name:"BaseComponent",props:{pt:{type:Object,default:void 0},ptOptions:{type:Object,default:void 0},unstyled:{type:Boolean,default:void 0},dt:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0}},watch:{isUnstyled:{immediate:!0,handler:function(t){z.off("theme:change",this._loadCoreStyles),t||(this._loadCoreStyles(),this._themeChangeListener(this._loadCoreStyles))}},dt:{immediate:!0,handler:function(t,n){var o=this;z.off("theme:change",this._themeScopedListener),t?(this._loadScopedThemeStyles(t),this._themeScopedListener=function(){return o._loadScopedThemeStyles(t)},this._themeChangeListener(this._themeScopedListener)):this._unloadScopedThemeStyles()}}},scopedStyleEl:void 0,rootEl:void 0,uid:void 0,$attrSelector:void 0,beforeCreate:function(){var t,n,o,r,i,s,l,a,u,d,c,p=(t=this.pt)===null||t===void 0?void 0:t._usept,m=p?(n=this.pt)===null||n===void 0||(n=n.originalValue)===null||n===void 0?void 0:n[this.$.type.name]:void 0,b=p?(o=this.pt)===null||o===void 0||(o=o.value)===null||o===void 0?void 0:o[this.$.type.name]:this.pt;(r=b||m)===null||r===void 0||(r=r.hooks)===null||r===void 0||(i=r.onBeforeCreate)===null||i===void 0||i.call(r);var _=(s=this.$primevueConfig)===null||s===void 0||(s=s.pt)===null||s===void 0?void 0:s._usept,h=_?(l=this.$primevue)===null||l===void 0||(l=l.config)===null||l===void 0||(l=l.pt)===null||l===void 0?void 0:l.originalValue:void 0,S=_?(a=this.$primevue)===null||a===void 0||(a=a.config)===null||a===void 0||(a=a.pt)===null||a===void 0?void 0:a.value:(u=this.$primevue)===null||u===void 0||(u=u.config)===null||u===void 0?void 0:u.pt;(d=S||h)===null||d===void 0||(d=d[this.$.type.name])===null||d===void 0||(d=d.hooks)===null||d===void 0||(c=d.onBeforeCreate)===null||c===void 0||c.call(d),this.$attrSelector=Tr(),this.uid=this.$attrs.id||this.$attrSelector.replace("pc","pv_id_")},created:function(){this._hook("onCreated")},beforeMount:function(){var t;this.rootEl=Ro(mt(this.$el)?this.$el:(t=this.$el)===null||t===void 0?void 0:t.parentElement,"[".concat(this.$attrSelector,"]")),this.rootEl&&(this.rootEl.$pc=P({name:this.$.type.name,attrSelector:this.$attrSelector},this.$params)),this._loadStyles(),this._hook("onBeforeMount")},mounted:function(){this._hook("onMounted")},beforeUpdate:function(){this._hook("onBeforeUpdate")},updated:function(){this._hook("onUpdated")},beforeUnmount:function(){this._hook("onBeforeUnmount")},unmounted:function(){this._removeThemeListeners(),this._unloadScopedThemeStyles(),this._hook("onUnmounted")},methods:{_hook:function(t){if(!this.$options.hostName){var n=this._usePT(this._getPT(this.pt,this.$.type.name),this._getOptionValue,"hooks.".concat(t)),o=this._useDefaultPT(this._getOptionValue,"hooks.".concat(t));n?.(),o?.()}},_mergeProps:function(t){for(var n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return Gt(t)?t.apply(void 0,o):Z.apply(void 0,o)},_load:function(){$e.isStyleNameLoaded("base")||(D.loadCSS(this.$styleOptions),this._loadGlobalStyles(),$e.setLoadedStyleName("base")),this._loadThemeStyles()},_loadStyles:function(){this._load(),this._themeChangeListener(this._load)},_loadCoreStyles:function(){var t,n;!$e.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name&&(_n.loadCSS(this.$styleOptions),this.$options.style&&this.$style.loadCSS(this.$styleOptions),$e.setLoadedStyleName(this.$style.name))},_loadGlobalStyles:function(){var t=this._useGlobalPT(this._getOptionValue,"global.css",this.$params);I(t)&&D.load(t,P({name:"global"},this.$styleOptions))},_loadThemeStyles:function(){var t,n;if(!(this.isUnstyled||this.$theme==="none")){if(!E.isStyleNameLoaded("common")){var o,r,i=((o=this.$style)===null||o===void 0||(r=o.getCommonTheme)===null||r===void 0?void 0:r.call(o))||{},s=i.primitive,l=i.semantic,a=i.global,u=i.style;D.load(s?.css,P({name:"primitive-variables"},this.$styleOptions)),D.load(l?.css,P({name:"semantic-variables"},this.$styleOptions)),D.load(a?.css,P({name:"global-variables"},this.$styleOptions)),D.loadStyle(P({name:"global-style"},this.$styleOptions),u),E.setLoadedStyleName("common")}if(!E.isStyleNameLoaded((t=this.$style)===null||t===void 0?void 0:t.name)&&(n=this.$style)!==null&&n!==void 0&&n.name){var d,c,p,m,b=((d=this.$style)===null||d===void 0||(c=d.getComponentTheme)===null||c===void 0?void 0:c.call(d))||{},_=b.css,h=b.style;(p=this.$style)===null||p===void 0||p.load(_,P({name:"".concat(this.$style.name,"-variables")},this.$styleOptions)),(m=this.$style)===null||m===void 0||m.loadStyle(P({name:"".concat(this.$style.name,"-style")},this.$styleOptions),h),E.setLoadedStyleName(this.$style.name)}if(!E.isStyleNameLoaded("layer-order")){var S,O,C=(S=this.$style)===null||S===void 0||(O=S.getLayerOrderThemeCSS)===null||O===void 0?void 0:O.call(S);D.load(C,P({name:"layer-order",first:!0},this.$styleOptions)),E.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(t){var n,o,r,i=((n=this.$style)===null||n===void 0||(o=n.getPresetTheme)===null||o===void 0?void 0:o.call(n,t,"[".concat(this.$attrSelector,"]")))||{},s=i.css,l=(r=this.$style)===null||r===void 0?void 0:r.load(s,P({name:"".concat(this.$attrSelector,"-").concat(this.$style.name)},this.$styleOptions));this.scopedStyleEl=l.el},_unloadScopedThemeStyles:function(){var t;(t=this.scopedStyleEl)===null||t===void 0||(t=t.value)===null||t===void 0||t.remove()},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};$e.clearLoadedStyleNames(),z.on("theme:change",t)},_removeThemeListeners:function(){z.off("theme:change",this._loadCoreStyles),z.off("theme:change",this._load),z.off("theme:change",this._themeScopedListener)},_getHostInstance:function(t){return t?this.$options.hostName?t.$.type.name===this.$options.hostName?t:this._getHostInstance(t.$parentInstance):t.$parentInstance:void 0},_getPropValue:function(t){var n;return this[t]||((n=this._getHostInstance(this))===null||n===void 0?void 0:n[t])},_getOptionValue:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return Yt(t,n,o)},_getPTValue:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{},i=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!0,s=/./g.test(o)&&!!r[o.split(".")[0]],l=this._getPropValue("ptOptions")||((t=this.$primevueConfig)===null||t===void 0?void 0:t.ptOptions)||{},a=l.mergeSections,u=a===void 0?!0:a,d=l.mergeProps,c=d===void 0?!1:d,p=i?s?this._useGlobalPT(this._getPTClassValue,o,r):this._useDefaultPT(this._getPTClassValue,o,r):void 0,m=s?void 0:this._getPTSelf(n,this._getPTClassValue,o,P(P({},r),{},{global:p||{}})),b=this._getPTDatasets(o);return u||!u&&m?c?this._mergeProps(c,p,m,b):P(P(P({},p),m),b):P(P({},m),b)},_getPTSelf:function(){for(var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length,o=new Array(n>1?n-1:0),r=1;r<n;r++)o[r-1]=arguments[r];return Z(this._usePT.apply(this,[this._getPT(t,this.$name)].concat(o)),this._usePT.apply(this,[this.$_attrsPT].concat(o)))},_getPTDatasets:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",r="data-pc-",i=o==="root"&&I((t=this.pt)===null||t===void 0?void 0:t["data-pc-section"]);return o!=="transition"&&P(P({},o==="root"&&P(P(Fe({},"".concat(r,"name"),me(i?(n=this.pt)===null||n===void 0?void 0:n["data-pc-section"]:this.$.type.name)),i&&Fe({},"".concat(r,"extend"),me(this.$.type.name))),{},Fe({},"".concat(this.$attrSelector),""))),{},Fe({},"".concat(r,"section"),me(o)))},_getPTClassValue:function(){var t=this._getOptionValue.apply(this,arguments);return te(t)||Nn(t)?{class:t}:t},_getPT:function(t){var n=this,o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",r=arguments.length>2?arguments[2]:void 0,i=function(l){var a,u=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,d=r?r(l):l,c=me(o),p=me(n.$name);return(a=u?c!==p?d?.[c]:void 0:d?.[c])!==null&&a!==void 0?a:d};return t!=null&&t.hasOwnProperty("_usept")?{_usept:t._usept,originalValue:i(t.originalValue),value:i(t.value)}:i(t,!0)},_usePT:function(t,n,o,r){var i=function(_){return n(_,o,r)};if(t!=null&&t.hasOwnProperty("_usept")){var s,l=t._usept||((s=this.$primevueConfig)===null||s===void 0?void 0:s.ptOptions)||{},a=l.mergeSections,u=a===void 0?!0:a,d=l.mergeProps,c=d===void 0?!1:d,p=i(t.originalValue),m=i(t.value);return p===void 0&&m===void 0?void 0:te(m)?m:te(p)?p:u||!u&&m?c?this._mergeProps(c,p,m):P(P({},p),m):m}return i(t)},_useGlobalPT:function(t,n,o){return this._usePT(this.globalPT,t,n,o)},_useDefaultPT:function(t,n,o){return this._usePT(this.defaultPT,t,n,o)},ptm:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this._getPTValue(this.pt,t,P(P({},this.$params),n))},ptmi:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",o=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},r=Z(this.$_attrsWithoutPT,this.ptm(n,o));return r?.hasOwnProperty("id")&&((t=r.id)!==null&&t!==void 0||(r.id=this.$id)),r},ptmo:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return this._getPTValue(t,n,P({instance:this},o),!1)},cx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return this.isUnstyled?void 0:this._getOptionValue(this.$style.classes,t,P(P({},this.$params),n))},sx:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,o=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};if(n){var r=this._getOptionValue(this.$style.inlineStyles,t,P(P({},this.$params),o)),i=this._getOptionValue(_n.inlineStyles,t,P(P({},this.$params),o));return[i,r]}}},computed:{globalPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return se(o,{instance:n})})},defaultPT:function(){var t,n=this;return this._getPT((t=this.$primevueConfig)===null||t===void 0?void 0:t.pt,void 0,function(o){return n._getOptionValue(o,n.$name,P({},n.$params))||se(o,P({},n.$params))})},isUnstyled:function(){var t;return this.unstyled!==void 0?this.unstyled:(t=this.$primevueConfig)===null||t===void 0?void 0:t.unstyled},$id:function(){return this.$attrs.id||this.uid},$inProps:function(){var t,n=Object.keys(((t=this.$.vnode)===null||t===void 0?void 0:t.props)||{});return Object.fromEntries(Object.entries(this.$props).filter(function(o){var r=We(o,1),i=r[0];return n?.includes(i)}))},$theme:function(){var t;return(t=this.$primevueConfig)===null||t===void 0?void 0:t.theme},$style:function(){return P(P({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},(this._getHostInstance(this)||{}).$style),this.$options.style)},$styleOptions:function(){var t;return{nonce:(t=this.$primevueConfig)===null||t===void 0||(t=t.csp)===null||t===void 0?void 0:t.nonce}},$primevueConfig:function(){var t;return(t=this.$primevue)===null||t===void 0?void 0:t.config},$name:function(){return this.$options.hostName||this.$.type.name},$params:function(){var t=this._getHostInstance(this)||this.$parent;return{instance:this,props:this.$props,state:this.$data,attrs:this.$attrs,parent:{instance:t,props:t?.$props,state:t?.$data,attrs:t?.$attrs}}},$_attrsPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=We(t,1),o=n[0];return o?.startsWith("pt:")}).reduce(function(t,n){var o=We(n,2),r=o[0],i=o[1],s=r.split(":"),l=xr(s),a=Wt(l).slice(1);return a?.reduce(function(u,d,c,p){return!u[d]&&(u[d]=c===p.length-1?i:{}),u[d]},t),t},{})},$_attrsWithoutPT:function(){return Object.entries(this.$attrs||{}).filter(function(t){var n=We(t,1),o=n[0];return!(o!=null&&o.startsWith("pt:"))}).reduce(function(t,n){var o=We(n,2),r=o[0],i=o[1];return t[r]=i,t},{})}}},jr=`
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
`,Nr=D.extend({name:"baseicon",css:jr});function at(e){"@babel/helpers - typeof";return at=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},at(e)}function kn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function wn(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?kn(Object(n),!0).forEach(function(o){Ir(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):kn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ir(e,t,n){return(t=Dr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Dr(e){var t=Rr(e,"string");return at(t)=="symbol"?t:t+""}function Rr(e,t){if(at(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(at(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Vr={name:"BaseIcon",extends:Qt,props:{label:{type:String,default:void 0},spin:{type:Boolean,default:!1}},style:Nr,provide:function(){return{$pcIcon:this,$parentInstance:this}},methods:{pti:function(){var t=Le(this.label);return wn(wn({},!this.isUnstyled&&{class:["p-icon",{"p-icon-spin":this.spin}]}),{},{role:t?void 0:"img","aria-label":t?void 0:this.label,"aria-hidden":t})}}},Fn={name:"SpinnerIcon",extends:Vr};function Mr(e){return Wr(e)||zr(e)||Ur(e)||Br()}function Br(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Ur(e,t){if(e){if(typeof e=="string")return qt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?qt(e,t):void 0}}function zr(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function Wr(e){if(Array.isArray(e))return qt(e)}function qt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function qr(e,t,n,o,r,i){return T(),L("svg",Z({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},e.pti()),Mr(t[0]||(t[0]=[B("path",{d:"M6.99701 14C5.85441 13.999 4.72939 13.7186 3.72012 13.1832C2.71084 12.6478 1.84795 11.8737 1.20673 10.9284C0.565504 9.98305 0.165424 8.89526 0.041387 7.75989C-0.0826496 6.62453 0.073125 5.47607 0.495122 4.4147C0.917119 3.35333 1.59252 2.4113 2.46241 1.67077C3.33229 0.930247 4.37024 0.413729 5.4857 0.166275C6.60117 -0.0811796 7.76026 -0.0520535 8.86188 0.251112C9.9635 0.554278 10.9742 1.12227 11.8057 1.90555C11.915 2.01493 11.9764 2.16319 11.9764 2.31778C11.9764 2.47236 11.915 2.62062 11.8057 2.73C11.7521 2.78503 11.688 2.82877 11.6171 2.85864C11.5463 2.8885 11.4702 2.90389 11.3933 2.90389C11.3165 2.90389 11.2404 2.8885 11.1695 2.85864C11.0987 2.82877 11.0346 2.78503 10.9809 2.73C9.9998 1.81273 8.73246 1.26138 7.39226 1.16876C6.05206 1.07615 4.72086 1.44794 3.62279 2.22152C2.52471 2.99511 1.72683 4.12325 1.36345 5.41602C1.00008 6.70879 1.09342 8.08723 1.62775 9.31926C2.16209 10.5513 3.10478 11.5617 4.29713 12.1803C5.48947 12.7989 6.85865 12.988 8.17414 12.7157C9.48963 12.4435 10.6711 11.7264 11.5196 10.6854C12.3681 9.64432 12.8319 8.34282 12.8328 7C12.8328 6.84529 12.8943 6.69692 13.0038 6.58752C13.1132 6.47812 13.2616 6.41667 13.4164 6.41667C13.5712 6.41667 13.7196 6.47812 13.8291 6.58752C13.9385 6.69692 14 6.84529 14 7C14 8.85651 13.2622 10.637 11.9489 11.9497C10.6356 13.2625 8.85432 14 6.99701 14Z",fill:"currentColor"},null,-1)])),16)}Fn.render=qr;var Hr=`
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
`,Kr={root:function(t){var n=t.props,o=t.instance;return["p-badge p-component",{"p-badge-circle":I(n.value)&&String(n.value).length===1,"p-badge-dot":Le(n.value)&&!o.$slots.default,"p-badge-sm":n.size==="small","p-badge-lg":n.size==="large","p-badge-xl":n.size==="xlarge","p-badge-info":n.severity==="info","p-badge-success":n.severity==="success","p-badge-warn":n.severity==="warn","p-badge-danger":n.severity==="danger","p-badge-secondary":n.severity==="secondary","p-badge-contrast":n.severity==="contrast"}]}},Fr=D.extend({name:"badge",style:Hr,classes:Kr}),Gr={name:"BaseBadge",extends:Qt,props:{value:{type:[String,Number],default:null},severity:{type:String,default:null},size:{type:String,default:null}},style:Fr,provide:function(){return{$pcBadge:this,$parentInstance:this}}};function it(e){"@babel/helpers - typeof";return it=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},it(e)}function $n(e,t,n){return(t=Yr(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Yr(e){var t=Qr(e,"string");return it(t)=="symbol"?t:t+""}function Qr(e,t){if(it(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(it(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var Gn={name:"Badge",extends:Gr,inheritAttrs:!1,computed:{dataP:function(){return Ye($n($n({circle:this.value!=null&&String(this.value).length===1,empty:this.value==null&&!this.$slots.default},this.severity,this.severity),this.size,this.size))}}},Zr=["data-p"];function Jr(e,t,n,o,r,i){return T(),L("span",Z({class:e.cx("root"),"data-p":i.dataP},e.ptmi("root")),[He(e.$slots,"default",{},function(){return[Qe(J(e.value),1)]})],16,Zr)}Gn.render=Jr;function st(e){"@babel/helpers - typeof";return st=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},st(e)}function Pn(e,t){return na(e)||ta(e,t)||ea(e,t)||Xr()}function Xr(){throw new TypeError(`Invalid attempt to destructure non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ea(e,t){if(e){if(typeof e=="string")return On(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?On(e,t):void 0}}function On(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function ta(e,t){var n=e==null?null:typeof Symbol<"u"&&e[Symbol.iterator]||e["@@iterator"];if(n!=null){var o,r,i,s,l=[],a=!0,u=!1;try{if(i=(n=n.call(e)).next,t!==0)for(;!(a=(o=i.call(n)).done)&&(l.push(o.value),l.length!==t);a=!0);}catch(d){u=!0,r=d}finally{try{if(!a&&n.return!=null&&(s=n.return(),Object(s)!==s))return}finally{if(u)throw r}}return l}}function na(e){if(Array.isArray(e))return e}function Tn(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter(function(r){return Object.getOwnPropertyDescriptor(e,r).enumerable})),n.push.apply(n,o)}return n}function x(e){for(var t=1;t<arguments.length;t++){var n=arguments[t]!=null?arguments[t]:{};t%2?Tn(Object(n),!0).forEach(function(o){Ht(e,o,n[o])}):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):Tn(Object(n)).forEach(function(o){Object.defineProperty(e,o,Object.getOwnPropertyDescriptor(n,o))})}return e}function Ht(e,t,n){return(t=oa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function oa(e){var t=ra(e,"string");return st(t)=="symbol"?t:t+""}function ra(e,t){if(st(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(st(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var w={_getMeta:function(){return[fe(arguments.length<=0?void 0:arguments[0])||arguments.length<=0?void 0:arguments[0],se(fe(arguments.length<=0?void 0:arguments[0])?arguments.length<=0?void 0:arguments[0]:arguments.length<=1?void 0:arguments[1])]},_getConfig:function(t,n){var o,r,i;return(o=(t==null||(r=t.instance)===null||r===void 0?void 0:r.$primevue)||(n==null||(i=n.ctx)===null||i===void 0||(i=i.appContext)===null||i===void 0||(i=i.config)===null||i===void 0||(i=i.globalProperties)===null||i===void 0?void 0:i.$primevue))===null||o===void 0?void 0:o.config},_getOptionValue:Yt,_getPTValue:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},i=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"",s=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{},l=arguments.length>4&&arguments[4]!==void 0?arguments[4]:!0,a=function(){var O=w._getOptionValue.apply(w,arguments);return te(O)||Nn(O)?{class:O}:O},u=((t=o.binding)===null||t===void 0||(t=t.value)===null||t===void 0?void 0:t.ptOptions)||((n=o.$primevueConfig)===null||n===void 0?void 0:n.ptOptions)||{},d=u.mergeSections,c=d===void 0?!0:d,p=u.mergeProps,m=p===void 0?!1:p,b=l?w._useDefaultPT(o,o.defaultPT(),a,i,s):void 0,_=w._usePT(o,w._getPT(r,o.$name),a,i,x(x({},s),{},{global:b||{}})),h=w._getPTDatasets(o,i);return c||!c&&_?m?w._mergeProps(o,m,b,_,h):x(x(x({},b),_),h):x(x({},_),h)},_getPTDatasets:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o="data-pc-";return x(x({},n==="root"&&Ht({},"".concat(o,"name"),me(t.$name))),{},Ht({},"".concat(o,"section"),me(n)))},_getPT:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",o=arguments.length>2?arguments[2]:void 0,r=function(s){var l,a=o?o(s):s,u=me(n);return(l=a?.[u])!==null&&l!==void 0?l:a};return t&&Object.hasOwn(t,"_usept")?{_usept:t._usept,originalValue:r(t.originalValue),value:r(t.value)}:r(t)},_usePT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0,s=function(h){return o(h,r,i)};if(n&&Object.hasOwn(n,"_usept")){var l,a=n._usept||((l=t.$primevueConfig)===null||l===void 0?void 0:l.ptOptions)||{},u=a.mergeSections,d=u===void 0?!0:u,c=a.mergeProps,p=c===void 0?!1:c,m=s(n.originalValue),b=s(n.value);return m===void 0&&b===void 0?void 0:te(b)?b:te(m)?m:d||!d&&b?p?w._mergeProps(t,p,m,b):x(x({},m),b):b}return s(n)},_useDefaultPT:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=arguments.length>2?arguments[2]:void 0,r=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0;return w._usePT(t,n,o,r,i)},_loadStyles:function(){var t,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},o=arguments.length>1?arguments[1]:void 0,r=arguments.length>2?arguments[2]:void 0,i=w._getConfig(o,r),s={nonce:i==null||(t=i.csp)===null||t===void 0?void 0:t.nonce};w._loadCoreStyles(n,s),w._loadThemeStyles(n,s),w._loadScopedThemeStyles(n,s),w._removeThemeListeners(n),n.$loadStyles=function(){return w._loadThemeStyles(n,s)},w._themeChangeListener(n.$loadStyles)},_loadCoreStyles:function(){var t,n,o=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},r=arguments.length>1?arguments[1]:void 0;if(!$e.isStyleNameLoaded((t=o.$style)===null||t===void 0?void 0:t.name)&&(n=o.$style)!==null&&n!==void 0&&n.name){var i;D.loadCSS(r),(i=o.$style)===null||i===void 0||i.loadCSS(r),$e.setLoadedStyleName(o.$style.name)}},_loadThemeStyles:function(){var t,n,o,r=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},i=arguments.length>1?arguments[1]:void 0;if(!(r!=null&&r.isUnstyled()||(r==null||(t=r.theme)===null||t===void 0?void 0:t.call(r))==="none")){if(!E.isStyleNameLoaded("common")){var s,l,a=((s=r.$style)===null||s===void 0||(l=s.getCommonTheme)===null||l===void 0?void 0:l.call(s))||{},u=a.primitive,d=a.semantic,c=a.global,p=a.style;D.load(u?.css,x({name:"primitive-variables"},i)),D.load(d?.css,x({name:"semantic-variables"},i)),D.load(c?.css,x({name:"global-variables"},i)),D.loadStyle(x({name:"global-style"},i),p),E.setLoadedStyleName("common")}if(!E.isStyleNameLoaded((n=r.$style)===null||n===void 0?void 0:n.name)&&(o=r.$style)!==null&&o!==void 0&&o.name){var m,b,_,h,S=((m=r.$style)===null||m===void 0||(b=m.getDirectiveTheme)===null||b===void 0?void 0:b.call(m))||{},O=S.css,C=S.style;(_=r.$style)===null||_===void 0||_.load(O,x({name:"".concat(r.$style.name,"-variables")},i)),(h=r.$style)===null||h===void 0||h.loadStyle(x({name:"".concat(r.$style.name,"-style")},i),C),E.setLoadedStyleName(r.$style.name)}if(!E.isStyleNameLoaded("layer-order")){var v,k,M=(v=r.$style)===null||v===void 0||(k=v.getLayerOrderThemeCSS)===null||k===void 0?void 0:k.call(v);D.load(M,x({name:"layer-order",first:!0},i)),E.setLoadedStyleName("layer-order")}}},_loadScopedThemeStyles:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},n=arguments.length>1?arguments[1]:void 0,o=t.preset();if(o&&t.$attrSelector){var r,i,s,l=((r=t.$style)===null||r===void 0||(i=r.getPresetTheme)===null||i===void 0?void 0:i.call(r,o,"[".concat(t.$attrSelector,"]")))||{},a=l.css,u=(s=t.$style)===null||s===void 0?void 0:s.load(a,x({name:"".concat(t.$attrSelector,"-").concat(t.$style.name)},n));t.scopedStyleEl=u.el}},_themeChangeListener:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:function(){};$e.clearLoadedStyleNames(),z.on("theme:change",t)},_removeThemeListeners:function(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};z.off("theme:change",t.$loadStyles),t.$loadStyles=void 0},_hook:function(t,n,o,r,i,s){var l,a,u="on".concat(Ao(n)),d=w._getConfig(r,i),c=o?.$instance,p=w._usePT(c,w._getPT(r==null||(l=r.value)===null||l===void 0?void 0:l.pt,t),w._getOptionValue,"hooks.".concat(u)),m=w._useDefaultPT(c,d==null||(a=d.pt)===null||a===void 0||(a=a.directives)===null||a===void 0?void 0:a[t],w._getOptionValue,"hooks.".concat(u)),b={el:o,binding:r,vnode:i,prevVnode:s};p?.(c,b),m?.(c,b)},_mergeProps:function(){for(var t=arguments.length>1?arguments[1]:void 0,n=arguments.length,o=new Array(n>2?n-2:0),r=2;r<n;r++)o[r-2]=arguments[r];return Gt(t)?t.apply(void 0,o):Z.apply(void 0,o)},_extend:function(t){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{},o=function(l,a,u,d,c){var p,m,b,_;a._$instances=a._$instances||{};var h=w._getConfig(u,d),S=a._$instances[t]||{},O=Le(S)?x(x({},n),n?.methods):{};a._$instances[t]=x(x({},S),{},{$name:t,$host:a,$binding:u,$modifiers:u?.modifiers,$value:u?.value,$el:S.$el||a||void 0,$style:x({classes:void 0,inlineStyles:void 0,load:function(){},loadCSS:function(){},loadStyle:function(){}},n?.style),$primevueConfig:h,$attrSelector:(p=a.$pd)===null||p===void 0||(p=p[t])===null||p===void 0?void 0:p.attrSelector,defaultPT:function(){return w._getPT(h?.pt,void 0,function(v){var k;return v==null||(k=v.directives)===null||k===void 0?void 0:k[t]})},isUnstyled:function(){var v,k;return((v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.unstyled)!==void 0?(k=a._$instances[t])===null||k===void 0||(k=k.$binding)===null||k===void 0||(k=k.value)===null||k===void 0?void 0:k.unstyled:h?.unstyled},theme:function(){var v;return(v=a._$instances[t])===null||v===void 0||(v=v.$primevueConfig)===null||v===void 0?void 0:v.theme},preset:function(){var v;return(v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.dt},ptm:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",M=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return w._getPTValue(a._$instances[t],(v=a._$instances[t])===null||v===void 0||(v=v.$binding)===null||v===void 0||(v=v.value)===null||v===void 0?void 0:v.pt,k,x({},M))},ptmo:function(){var v=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{},k=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"",M=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return w._getPTValue(a._$instances[t],v,k,M,!1)},cx:function(){var v,k,M=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",q=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};return(v=a._$instances[t])!==null&&v!==void 0&&v.isUnstyled()?void 0:w._getOptionValue((k=a._$instances[t])===null||k===void 0||(k=k.$style)===null||k===void 0?void 0:k.classes,M,x({},q))},sx:function(){var v,k=arguments.length>0&&arguments[0]!==void 0?arguments[0]:"",M=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!0,q=arguments.length>2&&arguments[2]!==void 0?arguments[2]:{};return M?w._getOptionValue((v=a._$instances[t])===null||v===void 0||(v=v.$style)===null||v===void 0?void 0:v.inlineStyles,k,x({},q)):void 0}},O),a.$instance=a._$instances[t],(m=(b=a.$instance)[l])===null||m===void 0||m.call(b,a,u,d,c),a["$".concat(t)]=a.$instance,w._hook(t,l,a,u,d,c),a.$pd||(a.$pd={}),a.$pd[t]=x(x({},(_=a.$pd)===null||_===void 0?void 0:_[t]),{},{name:t,instance:a._$instances[t]})},r=function(l){var a,u,d,c=l._$instances[t],p=c?.watch,m=function(h){var S,O=h.newValue,C=h.oldValue;return p==null||(S=p.config)===null||S===void 0?void 0:S.call(c,O,C)},b=function(h){var S,O=h.newValue,C=h.oldValue;return p==null||(S=p["config.ripple"])===null||S===void 0?void 0:S.call(c,O,C)};c.$watchersCallback={config:m,"config.ripple":b},p==null||(a=p.config)===null||a===void 0||a.call(c,c?.$primevueConfig),Pe.on("config:change",m),p==null||(u=p["config.ripple"])===null||u===void 0||u.call(c,c==null||(d=c.$primevueConfig)===null||d===void 0?void 0:d.ripple),Pe.on("config:ripple:change",b)},i=function(l){var a=l._$instances[t].$watchersCallback;a&&(Pe.off("config:change",a.config),Pe.off("config:ripple:change",a["config.ripple"]),l._$instances[t].$watchersCallback=void 0)};return{created:function(l,a,u,d){l.$pd||(l.$pd={}),l.$pd[t]={name:t,attrSelector:Wo("pd")},o("created",l,a,u,d)},beforeMount:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("beforeMount",l,a,u,d),r(l)},mounted:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("mounted",l,a,u,d)},beforeUpdate:function(l,a,u,d){o("beforeUpdate",l,a,u,d)},updated:function(l,a,u,d){var c;w._loadStyles((c=l.$pd[t])===null||c===void 0?void 0:c.instance,a,u),o("updated",l,a,u,d)},beforeUnmount:function(l,a,u,d){var c;i(l),w._removeThemeListeners((c=l.$pd[t])===null||c===void 0?void 0:c.instance),o("beforeUnmount",l,a,u,d)},unmounted:function(l,a,u,d){var c;(c=l.$pd[t])===null||c===void 0||(c=c.instance)===null||c===void 0||(c=c.scopedStyleEl)===null||c===void 0||(c=c.value)===null||c===void 0||c.remove(),o("unmounted",l,a,u,d)}}},extend:function(){var t=w._getMeta.apply(w,arguments),n=Pn(t,2),o=n[0],r=n[1];return x({extend:function(){var s=w._getMeta.apply(w,arguments),l=Pn(s,2),a=l[0],u=l[1];return w.extend(a,x(x(x({},r),r?.methods),u))}},w._extend(o,r))}},aa=`
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
`,ia={root:"p-ink"},sa=D.extend({name:"ripple-directive",style:aa,classes:ia}),la=w.extend({style:sa});function lt(e){"@babel/helpers - typeof";return lt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},lt(e)}function ua(e){return ma(e)||pa(e)||ca(e)||da()}function da(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function ca(e,t){if(e){if(typeof e=="string")return Kt(e,t);var n={}.toString.call(e).slice(8,-1);return n==="Object"&&e.constructor&&(n=e.constructor.name),n==="Map"||n==="Set"?Array.from(e):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Kt(e,t):void 0}}function pa(e){if(typeof Symbol<"u"&&e[Symbol.iterator]!=null||e["@@iterator"]!=null)return Array.from(e)}function ma(e){if(Array.isArray(e))return Kt(e)}function Kt(e,t){(t==null||t>e.length)&&(t=e.length);for(var n=0,o=Array(t);n<t;n++)o[n]=e[n];return o}function xn(e,t,n){return(t=fa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function fa(e){var t=ba(e,"string");return lt(t)=="symbol"?t:t+""}function ba(e,t){if(lt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(lt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var va=la.extend("ripple",{watch:{"config.ripple":function(t){t?(this.createRipple(this.$host),this.bindEvents(this.$host),this.$host.setAttribute("data-pd-ripple",!0),this.$host.style.overflow="hidden",this.$host.style.position="relative"):(this.remove(this.$host),this.$host.removeAttribute("data-pd-ripple"))}},unmounted:function(t){this.remove(t)},timeout:void 0,methods:{bindEvents:function(t){t.addEventListener("mousedown",this.onMouseDown.bind(this))},unbindEvents:function(t){t.removeEventListener("mousedown",this.onMouseDown.bind(this))},createRipple:function(t){var n=this.getInk(t);n||(n=Do("span",xn(xn({role:"presentation","aria-hidden":!0,"data-p-ink":!0,"data-p-ink-active":!1,class:!this.isUnstyled()&&this.cx("root"),onAnimationEnd:this.onAnimationEnd.bind(this)},this.$attrSelector,""),"p-bind",this.ptm("root"))),t.appendChild(n),this.$el=n)},remove:function(t){var n=this.getInk(t);n&&(this.$host.style.overflow="",this.$host.style.position="",this.unbindEvents(t),n.removeEventListener("animationend",this.onAnimationEnd),n.remove())},onMouseDown:function(t){var n=this,o=t.currentTarget,r=this.getInk(o);if(!(!r||getComputedStyle(r,null).display==="none")){if(!this.isUnstyled()&&Dt(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"),!an(r)&&!sn(r)){var i=Math.max(jo(o),Bo(o));r.style.height=i+"px",r.style.width=i+"px"}var s=Mo(o),l=t.pageX-s.left+document.body.scrollTop-sn(r)/2,a=t.pageY-s.top+document.body.scrollLeft-an(r)/2;r.style.top=a+"px",r.style.left=l+"px",!this.isUnstyled()&&Eo(r,"p-ink-active"),r.setAttribute("data-p-ink-active","true"),this.timeout=setTimeout(function(){r&&(!n.isUnstyled()&&Dt(r,"p-ink-active"),r.setAttribute("data-p-ink-active","false"))},401)}},onAnimationEnd:function(t){this.timeout&&clearTimeout(this.timeout),!this.isUnstyled()&&Dt(t.currentTarget,"p-ink-active"),t.currentTarget.setAttribute("data-p-ink-active","false")},getInk:function(t){return t&&t.children?ua(t.children).find(function(n){return Vo(n,"data-pc-name")==="ripple"}):void 0}}}),ga=`
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
`;function ut(e){"@babel/helpers - typeof";return ut=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},ut(e)}function pe(e,t,n){return(t=ha(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function ha(e){var t=ya(e,"string");return ut(t)=="symbol"?t:t+""}function ya(e,t){if(ut(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(ut(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var _a={root:function(t){var n=t.instance,o=t.props;return["p-button p-component",pe(pe(pe(pe(pe(pe(pe(pe(pe({"p-button-icon-only":n.hasIcon&&!o.label&&!o.badge,"p-button-vertical":(o.iconPos==="top"||o.iconPos==="bottom")&&o.label,"p-button-loading":o.loading,"p-button-link":o.link||o.variant==="link"},"p-button-".concat(o.severity),o.severity),"p-button-raised",o.raised),"p-button-rounded",o.rounded),"p-button-text",o.text||o.variant==="text"),"p-button-outlined",o.outlined||o.variant==="outlined"),"p-button-sm",o.size==="small"),"p-button-lg",o.size==="large"),"p-button-plain",o.plain),"p-button-fluid",n.hasFluid)]},loadingIcon:"p-button-loading-icon",icon:function(t){var n=t.props;return["p-button-icon",pe({},"p-button-icon-".concat(n.iconPos),n.label)]},label:"p-button-label"},Sa=D.extend({name:"button",style:ga,classes:_a}),ka={name:"BaseButton",extends:Qt,props:{label:{type:String,default:null},icon:{type:String,default:null},iconPos:{type:String,default:"left"},iconClass:{type:[String,Object],default:null},badge:{type:String,default:null},badgeClass:{type:[String,Object],default:null},badgeSeverity:{type:String,default:"secondary"},loading:{type:Boolean,default:!1},loadingIcon:{type:String,default:void 0},as:{type:[String,Object],default:"BUTTON"},asChild:{type:Boolean,default:!1},link:{type:Boolean,default:!1},severity:{type:String,default:null},raised:{type:Boolean,default:!1},rounded:{type:Boolean,default:!1},text:{type:Boolean,default:!1},outlined:{type:Boolean,default:!1},size:{type:String,default:null},variant:{type:String,default:null},plain:{type:Boolean,default:!1},fluid:{type:Boolean,default:null}},style:Sa,provide:function(){return{$pcButton:this,$parentInstance:this}}};function dt(e){"@babel/helpers - typeof";return dt=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(t){return typeof t}:function(t){return t&&typeof Symbol=="function"&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},dt(e)}function Q(e,t,n){return(t=wa(t))in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function wa(e){var t=$a(e,"string");return dt(t)=="symbol"?t:t+""}function $a(e,t){if(dt(e)!="object"||!e)return e;var n=e[Symbol.toPrimitive];if(n!==void 0){var o=n.call(e,t);if(dt(o)!="object")return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return(t==="string"?String:Number)(e)}var ct={name:"Button",extends:ka,inheritAttrs:!1,inject:{$pcFluid:{default:null}},methods:{getPTOptions:function(t){var n=t==="root"?this.ptmi:this.ptm;return n(t,{context:{disabled:this.disabled}})}},computed:{disabled:function(){return this.$attrs.disabled||this.$attrs.disabled===""||this.loading},defaultAriaLabel:function(){return this.label?this.label+(this.badge?" "+this.badge:""):this.$attrs.ariaLabel},hasIcon:function(){return this.icon||this.$slots.icon},attrs:function(){return Z(this.asAttrs,this.a11yAttrs,this.getPTOptions("root"))},asAttrs:function(){return this.as==="BUTTON"?{type:"button",disabled:this.disabled}:void 0},a11yAttrs:function(){return{"aria-label":this.defaultAriaLabel,"data-pc-name":"button","data-p-disabled":this.disabled,"data-p-severity":this.severity}},hasFluid:function(){return Le(this.fluid)?!!this.$pcFluid:this.fluid},dataP:function(){return Ye(Q(Q(Q(Q(Q(Q(Q(Q(Q(Q({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge),"loading",this.loading),"fluid",this.hasFluid),"rounded",this.rounded),"raised",this.raised),"outlined",this.outlined||this.variant==="outlined"),"text",this.text||this.variant==="text"),"link",this.link||this.variant==="link"),"vertical",(this.iconPos==="top"||this.iconPos==="bottom")&&this.label))},dataIconP:function(){return Ye(Q(Q({},this.iconPos,this.iconPos),this.size,this.size))},dataLabelP:function(){return Ye(Q(Q({},this.size,this.size),"icon-only",this.hasIcon&&!this.label&&!this.badge))}},components:{SpinnerIcon:Fn,Badge:Gn},directives:{ripple:va}},Pa=["data-p"],Oa=["data-p"];function Ta(e,t,n,o,r,i){var s=Ut("SpinnerIcon"),l=Ut("Badge"),a=uo("ripple");return e.asChild?He(e.$slots,"default",{key:1,class:Re(e.cx("root")),a11yAttrs:i.a11yAttrs}):co((T(),De(po(e.as),Z({key:0,class:e.cx("root"),"data-p":i.dataP},i.attrs),{default:Ze(function(){return[He(e.$slots,"default",{},function(){return[e.loading?He(e.$slots,"loadingicon",Z({key:0,class:[e.cx("loadingIcon"),e.cx("icon")]},e.ptm("loadingIcon")),function(){return[e.loadingIcon?(T(),L("span",Z({key:0,class:[e.cx("loadingIcon"),e.cx("icon"),e.loadingIcon]},e.ptm("loadingIcon")),null,16)):(T(),De(s,Z({key:1,class:[e.cx("loadingIcon"),e.cx("icon")],spin:""},e.ptm("loadingIcon")),null,16,["class"]))]}):He(e.$slots,"icon",Z({key:1,class:[e.cx("icon")]},e.ptm("icon")),function(){return[e.icon?(T(),L("span",Z({key:0,class:[e.cx("icon"),e.icon,e.iconClass],"data-p":i.dataIconP},e.ptm("icon")),null,16,Pa)):ee("",!0)]}),e.label?(T(),L("span",Z({key:2,class:e.cx("label")},e.ptm("label"),{"data-p":i.dataLabelP}),J(e.label),17,Oa)):ee("",!0),e.badge?(T(),De(l,{key:3,value:e.badge,class:Re(e.badgeClass),severity:e.badgeSeverity,unstyled:e.unstyled,pt:e.ptm("pcBadge")},null,8,["value","class","severity","unstyled","pt"])):ee("",!0)]})]}),_:3},16,["class","data-p"])),[[a]])}ct.render=Ta;const Yn=Symbol("host_api"),Qn=Symbol("axios"),Zn=Symbol("proxy"),xa=Symbol("config"),Ca=Symbol("on_subscription");function Aa(){const e=Ft(Yn);if(!e)throw new Error("HostApi not provided");return e}function La(){const e=Ft(Qn);if(!e)throw new Error("ProxyApiInstance not provided");return e}function Ea(){const e=Ft(Zn);if(!e)throw new Error("WIPPY_INSTANCE not provided");return e}const Ei={changeset:"keeper.changeset",git:"keeper.git",version:"registry:version"};async function ja(e){const{data:t}=await e.post("/api/v1/keeper/events/subscribe",{});return t}async function Na(e){const{data:t}=await e.post("/api/v1/keeper/events/unsubscribe",{});return t}const Zt="keeper.events.muted",Ve=R(!1),Tt=R(localStorage.getItem(Zt)==="1"),kt=R(!1),pt=R(null);function Jn(e){return e?.response?.data?.error||e?.message||"request failed"}async function Xn(e,t=!1){if(!(Tt.value||kt.value)&&!(Ve.value&&!t)){kt.value=!0;try{const n=await ja(e);Ve.value=n.subscribed===!0,pt.value=null}catch(n){Ve.value=!1,pt.value=Jn(n)}finally{kt.value=!1}}}async function Ia(e){if(Tt.value=!0,localStorage.setItem(Zt,"1"),!!Ve.value)try{await Na(e),Ve.value=!1,pt.value=null}catch(t){pt.value=Jn(t)}}async function Da(e){Tt.value=!1,localStorage.removeItem(Zt),await Xn(e,!0)}function Ra(){return{subscribed:Ve,muted:Tt,pending:kt,error:pt,ensureSubscribed:Xn,mute:Ia,unmute:Da}}async function ji(e){const{data:t}=await e.get("/api/v1/keeper/registry/namespaces");return t}async function Ni(e,t={}){const n={limit:t.limit||200,offset:t.offset||0};t.namespace&&(n.namespace=t.namespace),t.kind&&(n.kind=t.kind),t.metaType&&(n["meta.type"]=t.metaType),t.query&&(n.q=t.query);const{data:o}=await e.get("/api/v1/keeper/registry/entries",{params:n});return o}async function Ii(e,t){const{data:n}=await e.get("/api/v1/keeper/registry/entry",{params:{id:t}});return n}async function Di(e,t,n){const{data:o}=await e.put("/api/v1/keeper/registry/entry",n,{params:{id:t}});return o}async function Ri(e,t){const n={};t&&(n.namespace=t);const{data:o}=await e.get("/api/v1/keeper/state/graph",{params:n});return o}async function Vi(e){const{data:t}=await e.get("/api/v1/keeper/env/list");return t}async function Mi(e,t,n){const{data:o}=await e.post("/api/v1/keeper/env/set",{key:t,value:n});return o}async function Bi(e){const{data:t}=await e.get("/api/v1/keeper/sync/state");return t}async function Ui(e){const{data:t}=await e.get("/api/v1/keeper/sync/config");return t}async function zi(e,t){const{data:n}=await e.put("/api/v1/keeper/sync/config",{managed_namespaces:t});return n}async function Wi(e){const{data:t}=await e.post("/api/v1/keeper/sync/download");return t}async function qi(e){const{data:t}=await e.post("/api/v1/keeper/sync/upload");return t}async function Hi(e){const{data:t}=await e.post("/api/v1/keeper/sync/undo");return t}async function Ki(e){const{data:t}=await e.post("/api/v1/keeper/sync/redo");return t}const Mt={"ns.definition":"var(--p-info-500)","ns.requirement":"var(--p-warn-500)","ns.dependency":"var(--p-accent-400)","http.service":"var(--p-success-500)","http.router":"var(--p-success-500)","http.endpoint":"var(--p-info-500)","http.static":"var(--p-info-500)","function.lua":"var(--p-warn-500)","library.lua":"var(--p-warn-500)","process.lua":"var(--p-warn-500)","registry.entry":"var(--p-accent-500)","db.sql.sqlite":"var(--p-accent-500)","fs.directory":"var(--p-text-muted-color)","fs.embed":"var(--p-text-muted-color)","process.host":"var(--p-info-500)","store.memory":"var(--p-accent-500)","store.sql":"var(--p-accent-500)","env.variable":"var(--p-text-muted-color)","env.composite":"var(--p-text-muted-color)","env.file":"var(--p-text-muted-color)","env.os":"var(--p-text-muted-color)","env.memory":"var(--p-text-muted-color)","security.policy":"var(--p-danger-500)","view.page":"var(--p-info-500)","view.component":"var(--p-info-500)","queue.memory":"var(--p-accent-500)","queue.consumer":"var(--p-accent-500)","template.set":"var(--p-warn-500)",contract:"var(--p-accent-400)","agent.gen1":"var(--p-warn-500)","agent.trait":"var(--p-warn-500)","llm.model":"var(--p-accent-500)",tool:"var(--p-info-500)"},Bt={"ns.definition":"tabler:package","ns.requirement":"tabler:plug","ns.dependency":"tabler:link","http.service":"tabler:server","http.router":"tabler:route","http.endpoint":"tabler:api","http.static":"tabler:file","function.lua":"tabler:code","library.lua":"tabler:book","process.lua":"tabler:code","registry.entry":"tabler:database","db.sql.sqlite":"tabler:database","fs.directory":"tabler:folder","fs.embed":"tabler:folder","process.host":"tabler:cpu","store.memory":"tabler:database","store.sql":"tabler:database","env.variable":"tabler:variable","env.composite":"tabler:variable","env.file":"tabler:variable","env.os":"tabler:variable","env.memory":"tabler:variable","security.policy":"tabler:shield-check","view.page":"tabler:browser","view.component":"tabler:components","queue.memory":"tabler:list","queue.consumer":"tabler:player-play","template.set":"tabler:template",contract:"tabler:file-certificate","agent.gen1":"tabler:robot","agent.trait":"tabler:sparkles","llm.model":"tabler:brain",tool:"tabler:tool"};function wt(e,t){return t&&Mt[t]?Mt[t]:Mt[e]||"var(--p-text-muted-color)"}function eo(e,t){return t&&Bt[t]?Bt[t]:Bt[e]||"tabler:circle"}async function Fi(e,t=100,n=0){const{data:o}=await e.get("/api/v1/sessions",{params:{limit:t,offset:n}});return o}async function Gi(e,t){const{data:n}=await e.get("/api/v1/sessions/get",{params:{session_id:t}});return n}async function Yi(e,t,n=50,o=""){const{data:r}=await e.get("/api/v1/sessions/messages",{params:{session_id:t,limit:n,cursor:o}});return r}function Qi(e){return!e||e===0?"0":e>=1e6?(e/1e6).toFixed(1)+"M":e>=1e3?(e/1e3).toFixed(1)+"K":e.toString()}function Cn(e){if(!e)return"";let t;typeof e=="number"?e>1e15?t=e/1e6:e>1e12?t=e/1e3:e>1e10?t=e:t=e*1e3:t=new Date(e).getTime();const n=new Date(t);if(isNaN(n.getTime()))return"";const r=Math.floor((new Date().getTime()-n.getTime())/1e3);if(r<60)return"just now";const i=Math.floor(r/60);if(i<60)return`${i}m ago`;const s=Math.floor(i/60);if(s<24)return`${s}h ago`;const l=Math.floor(s/24);if(l<30)return`${l}d ago`;const a=Math.floor(l/30);return a<12?`${a}mo ago`:`${Math.floor(a/12)}y ago`}function Zi(e){return e?new Date(typeof e=="number"?e*1e3:e).toLocaleString():"N/A"}const Va={key:0,class:"status-dropdown"},Ma=["onClick"],Ba={key:0,class:"plugin-tag",title:"Provided by a registered plugin"},Ua=Ae({__name:"AppNavDropdown",props:{icon:{},label:{},items:{},open:{type:Boolean},active:{type:Boolean},currentName:{},wrapClass:{}},emits:["toggle","navigate"],setup(e,{emit:t}){const n=t;function o(r){n("navigate",r)}return(r,i)=>(T(),L("div",{class:Re(["relative",e.wrapClass])},[j(V(ct),{variant:"text",class:Re(["k-btn-nav relative !gap-1.5",{"k-btn-active":e.active}]),onClick:i[0]||(i[0]=s=>n("toggle"))},{default:Ze(()=>[j(V(X),{icon:e.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Qe(" "+J(e.label)+" ",1),j(V(X),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.5"}})]),_:1},8,["class"]),e.open?(T(),L("div",Va,[(T(!0),L(Je,null,Xe(e.items,s=>(T(),L("button",{key:s.name,class:Re(["status-item",{"status-item--active":e.currentName===s.name}]),onClick:l=>o(s.path)},[j(V(X),{icon:s.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Qe(" "+J(s.label)+" ",1),s.name.startsWith("plugin:")?(T(),L("span",Ba,"plugin")):ee("",!0)],10,Ma))),128))])):ee("",!0)],2))}}),to=(e,t)=>{const n=e.__vccOpts||e;for(const[o,r]of t)n[o]=r;return n},qe=to(Ua,[["__scopeId","data-v-6d403115"]]),za={class:"truncate",style:{"max-width":"80px"}},Wa={key:1,class:"relative agent-dropdown-wrap"},qa={key:0,class:"agent-dropdown"},Ha=["onClick"],Ka={class:"agent-item-copy"},Fa={class:"agent-item-title"},Ga={key:0,class:"agent-item-comment"},Ya=Ae({__name:"AppAgentLauncher",props:{agents:{},open:{type:Boolean}},emits:["toggle","start"],setup(e,{emit:t}){const n=t;return(o,r)=>e.agents.length===1?(T(),L("button",{key:0,class:"ask-btn",onClick:r[0]||(r[0]=i=>n("start",e.agents[0].start_token))},[j(V(X),{icon:e.agents[0].icon||"tabler:message-bolt",class:"w-3.5 h-3.5"},null,8,["icon"]),B("span",za,J(e.agents[0].title||"Ask"),1)])):e.agents.length>1?(T(),L("div",Wa,[B("button",{class:"ask-btn",onClick:r[1]||(r[1]=i=>n("toggle"))},[j(V(X),{icon:"tabler:message-bolt",class:"w-3.5 h-3.5"}),r[2]||(r[2]=Qe(" Ask ",-1)),j(V(X),{icon:"tabler:chevron-down",class:"w-2.5 h-2.5",style:{opacity:"0.6"}})]),e.open?(T(),L("div",qa,[(T(!0),L(Je,null,Xe(e.agents,i=>(T(),L("button",{key:i.id,class:"agent-item",onClick:s=>n("start",i.start_token)},[j(V(X),{icon:i.icon||"tabler:robot",class:"agent-item-icon"},null,8,["icon"]),B("span",Ka,[B("span",Fa,J(i.title||i.id),1),i.comment?(T(),L("span",Ga,J(i.comment),1)):ee("",!0)])],8,Ha))),128))])):ee("",!0)])):ee("",!0)}}),Qa=to(Ya,[["__scopeId","data-v-eeb14e8e"]]),Za={key:0,class:"flex items-center gap-1.5 text-xs pl-2",style:{color:"var(--p-text-muted-color)","border-left":"1px solid var(--p-content-border-color)"}},Ja={class:"truncate max-w-[100px]"},Xa=Ae({__name:"AppUserChip",props:{user:{}},emits:["logout"],setup(e,{emit:t}){const n=t;return(o,r)=>e.user?(T(),L("div",Za,[B("span",Ja,J(e.user.full_name||e.user.email),1),j(V(ct),{class:"k-btn-icon !w-6 !h-6 !p-0 !rounded-full",title:"Logout",onClick:r[0]||(r[0]=i=>n("logout"))},{default:Ze(()=>[j(V(X),{icon:"tabler:logout",class:"w-3 h-3"})]),_:1})])):ee("",!0)}}),ei={class:"search-modal"},ti={class:"search-header"},ni=["value"],oi={key:0,class:"search-results"},ri=["onClick"],ai={class:"flex-1 min-w-0"},ii={class:"text-[11px] font-mono truncate",style:{color:"var(--p-text-color)"}},si={key:0,class:"text-[9px] truncate",style:{color:"var(--p-text-muted-color)"}},li={key:1,class:"search-empty"},ui={key:2,class:"search-hints"},di=["onClick"],ci={class:"text-[10px] font-mono",style:{color:"var(--p-primary-color)"}},pi={class:"text-[10px]",style:{color:"var(--p-text-muted-color)"}},mi=Ae({__name:"AppGlobalSearch",props:{open:{type:Boolean},query:{},results:{},loading:{type:Boolean},hints:{}},emits:["update:query","close","search-input","select","apply-hint"],setup(e,{emit:t}){const n=t;function o(r){r.length>0&&n("select",r[0])}return(r,i)=>(T(),De(mo,{to:"body"},[e.open?(T(),L("div",{key:0,class:"search-overlay",onClick:i[3]||(i[3]=fo(s=>n("close"),["self"]))},[B("div",ei,[B("div",ti,[j(V(X),{icon:"tabler:search",class:"w-4 h-4 shrink-0",style:{color:"var(--p-text-muted-color)"}}),B("input",{value:e.query,onInput:i[0]||(i[0]=s=>{n("update:query",s.target.value),n("search-input")}),onKeydown:[i[1]||(i[1]=en(s=>n("close"),["escape"])),i[2]||(i[2]=en(s=>o(e.results),["enter"]))],class:"global-search-input",placeholder:"Search entries, functions, configs...",autofocus:""},null,40,ni),e.loading?(T(),De(V(X),{key:0,icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin",style:{color:"var(--p-primary-color)"}})):ee("",!0),i[4]||(i[4]=B("kbd",{class:"search-kbd"},"Esc",-1))]),e.results.length>0?(T(),L("div",oi,[(T(!0),L(Je,null,Xe(e.results,s=>(T(),L("div",{key:s.id,class:"search-item",onClick:l=>n("select",s)},[j(V(X),{icon:s.icon||V(eo)(s.kind),class:"w-3 h-3 shrink-0",style:tn({color:s.color||V(wt)(s.kind)})},null,8,["icon","style"]),B("div",ai,[B("div",ii,J(s.id),1),s.snippet?(T(),L("div",si,J(s.snippet),1)):ee("",!0)]),B("span",{class:"text-[8px] px-1 rounded",style:tn({color:s.color||V(wt)(s.kind),background:`color-mix(in srgb, ${s.color||V(wt)(s.kind)} 12%, transparent)`})},J(s.kind),5)],8,ri))),128))])):e.query&&!e.loading?(T(),L("div",li,"No results")):e.query?ee("",!0):(T(),L("div",ui,[(T(!0),L(Je,null,Xe(e.hints,s=>(T(),L("div",{key:s.prefix,class:"search-hint",onClick:l=>n("apply-hint",s.prefix)},[j(V(X),{icon:s.icon,class:"w-3 h-3 shrink-0",style:{color:"var(--p-text-muted-color)"}},null,8,["icon"]),B("span",ci,J(s.prefix||"*"),1),B("span",pi,J(s.desc),1)],8,di))),128))]))])])):ee("",!0)]))}}),fi={class:"h-full flex flex-col"},bi={class:"shrink-0 h-10 flex items-center px-3 gap-3",style:{background:"var(--p-content-background)","border-bottom":"1px solid var(--p-content-border-color)"}},vi={class:"flex items-center gap-0.5 flex-1"},gi={class:"flex items-center gap-1.5 shrink-0"},hi={class:"flex-1 overflow-y-auto",style:{background:"color-mix(in srgb, var(--p-content-background) 94%, var(--p-text-color) 6%)"}},yi=Ae({__name:"app",setup(e){const t=En(),n=go(),o=La(),r=Aa(),i=Ea(),s=Ra(),l=R(0),a=R(0);let u=null,d=null,c=null;async function p(){try{const{data:f}=await o.get("/api/v1/keeper/logger/stats");f.success&&f.stats?.counters&&(l.value=f.stats.counters.error||0,a.value=f.stats.counters.warn||0)}catch{}}const m=[{path:"/",name:"dashboard",label:"Home",icon:"tabler:layout-dashboard"}],b=[{path:"/settings/environment",name:"settings-environment",label:"Environment",icon:"tabler:variable"},{path:"/settings/registry",name:"settings-registry",label:"Registry",icon:"tabler:database"},{path:"/settings/hub",name:"settings-hub",label:"Wippy Hub",icon:"tabler:cloud"},{path:"/mcp",name:"mcp",label:"MCP",icon:"tabler:plug-connected"}],_=[{path:"/sessions",name:"sessions",label:"Sessions",icon:"tabler:list"},{path:"/dataflows",name:"workflow",label:"Dataflows",icon:"tabler:git-merge"},{path:"/system",name:"system",label:"System",icon:"tabler:activity"},{path:"/logs",name:"logs",label:"Logs",icon:"tabler:file-text"},{path:"/activity",name:"activity",label:"Activity",icon:"tabler:broadcast"}],h=[],S=[{path:"/structure",name:"structure",label:"Registry",icon:"tabler:binary-tree"},{path:"/agents",name:"agents",label:"Agents",icon:"tabler:robot"},{path:"/models",name:"models",label:"Models",icon:"tabler:brain"},{path:"/tools",name:"tools",label:"Tools",icon:"tabler:tool"},{path:"/traits",name:"traits",label:"Traits",icon:"tabler:sparkles"},{path:"/endpoints",name:"endpoints",label:"Endpoints",icon:"tabler:api"},{path:"/policies",name:"policies",label:"Policies",icon:"tabler:shield-check"}],O=[{path:"/tasks",name:"tasks",label:"Pipeline",icon:"tabler:git-merge"},{path:"/changes",name:"changes",label:"Changes",icon:"tabler:git-branch"},{path:"/components",name:"components",label:"Components",icon:"tabler:puzzle"},{path:"/knowledge",name:"knowledge",label:"Knowledge",icon:"tabler:brain"},{path:"/tests",name:"tests",label:"Tests",icon:"tabler:test-pipe"}],C=R([]);async function v(){try{const{data:f}=await o.get("/api/public/pages/list");if(!f?.success||!Array.isArray(f.pages))return;C.value=f.pages.filter(g=>g.announced&&g.id.startsWith("keeper.")&&g.id!=="keeper:main").sort((g,ie)=>(g.order||9999)-(ie.order||9999)||g.title.localeCompare(ie.title)).map(g=>({path:`/plugin/${g.id}`,name:`plugin:${g.id}`,label:g.title||g.name,icon:g.icon||"tabler:puzzle",group:g.group||"develop"}))}catch{}}const k=K(()=>[..._,...C.value.filter(f=>f.group==="observe")]),M=K(()=>[...S,...C.value.filter(f=>f.group==="structure")]),q=K(()=>[...O,...C.value.filter(f=>f.group==="develop"||!f.group)]),le=K(()=>[...h,...C.value.filter(f=>f.group==="status")]),F=R(!1),ne=R(!1),G=R(!1),oe=R(!1),re=R(!1),H=R(!1),be=K(()=>new Set(le.value.map(f=>f.name))),ye=K(()=>new Set(M.value.map(f=>f.name))),ve=K(()=>new Set(q.value.map(f=>f.name))),_e=K(()=>new Set(k.value.map(f=>f.name))),Se=K(()=>new Set(b.map(f=>f.name))),N=K(()=>n.name),ue=K(()=>be.value.has(String(N.value))),ge=K(()=>ye.value.has(String(N.value))),Ee=K(()=>ve.value.has(String(N.value))),ke=K(()=>_e.value.has(String(N.value))||N.value==="session-detail"||N.value==="dataflow-detail"),ft=K(()=>Se.value.has(String(N.value))||N.value==="settings"),Me=R(null);function Be(f){t.push(f)}function xt(){F.value=!1,ne.value=!1,G.value=!1,oe.value=!1,re.value=!1,H.value=!1}function Oe(f){Be(f),xt()}async function Ct(){try{const{data:f}=await o.get("/api/v1/user/me");f.success&&f.user&&(Me.value={email:f.user.email,full_name:f.user.full_name})}catch{}}const bt=R([]);async function At(){try{const{data:f}=await o.get("/api/v1/keeper/agents/list",{params:{public_only:!0}});bt.value=f.agents||[]}catch{}}function Lt(f){r.startChat(f,{sidebar:!0}),H.value=!1}const we=R(!1),Te=R(""),ae=R([]),Ue=R(!1);let ze=null;const Et=[{prefix:"session:",desc:"Search sessions by title or ID",icon:"tabler:list"},{prefix:"dataflow:",desc:"Search dataflows",icon:"tabler:git-merge"},{prefix:"agent:",desc:"Search agents",icon:"tabler:robot"},{prefix:"model:",desc:"Search LLM models",icon:"tabler:brain"},{prefix:"tool:",desc:"Search tools",icon:"tabler:tool"},{prefix:"endpoint:",desc:"Search HTTP endpoints",icon:"tabler:api"},{prefix:"",desc:"Search all registry entries",icon:"tabler:search"}];async function vt(){const f=Te.value.trim();if(!f){ae.value=[];return}Ue.value=!0;try{const g=f.indexOf(":"),ie=g>0?f.slice(0,g).toLowerCase():"",$=g>0?f.slice(g+1).trim():f;if(ie==="session"){const{data:Y}=await o.get("/api/v1/sessions",{params:{limit:20}}),U=(Y.sessions||[]).filter(y=>!$||y.title?.toLowerCase().includes($.toLowerCase())||y.session_id?.includes($)||y.current_agent?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.title||y.session_id?.slice(0,12)+"...",kind:y.current_agent||"session",snippet:[y.current_model,y.status,Cn(y.last_message_date||y.start_date)].filter(Boolean).join(" · "),icon:"tabler:message",color:"var(--p-info-500)",route:"/session/"+y.session_id}))}else if(ie==="dataflow"){const{data:Y}=await o.get("/api/v1/dataflows",{params:{limit:20}}),U=(Y.dataflows||[]).filter(y=>!$||y.metadata?.title?.toLowerCase().includes($.toLowerCase())||y.dataflow_id?.includes($));ae.value=U.slice(0,15).map(y=>({id:y.metadata?.title||y.dataflow_id?.slice(0,12)+"...",kind:y.status||"dataflow",snippet:[y.type,Cn(y.created_at)].filter(Boolean).join(" · "),icon:"tabler:git-merge",color:y.status==="running"?"var(--p-success-500)":y.status==="failed"?"var(--p-danger-500)":"var(--p-info-500)",route:"/dataflow/"+y.dataflow_id}))}else if(ie==="agent"){const{data:Y}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"agent.gen1",limit:100}}),U=(Y.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.title||"",icon:"tabler:robot",color:"var(--p-warn-500)",route:"/structure?entry="+y.id}))}else if(ie==="model"){const{data:Y}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"llm.model",limit:100}}),U=(Y.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.title||"",icon:"tabler:brain",color:"var(--p-accent-500)",route:"/structure?entry="+y.id}))}else if(ie==="tool"){const{data:Y}=await o.get("/api/v1/keeper/registry/entries",{params:{"meta.type":"tool",limit:100}}),U=(Y.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase())||y.meta?.title?.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.comment||y.meta?.llm_alias||"",icon:"tabler:tool",color:"var(--p-info-500)",route:"/structure?entry="+y.id}))}else if(ie==="endpoint"){const{data:Y}=await o.get("/api/v1/keeper/registry/entries",{params:{kind:"http.endpoint",limit:200}}),U=(Y.entries||[]).filter(y=>!$||y.id.toLowerCase().includes($.toLowerCase()));ae.value=U.slice(0,15).map(y=>({id:y.id,kind:y.kind,snippet:y.meta?.comment||"",icon:"tabler:api",color:"var(--p-info-500)",route:"/structure?entry="+y.id}))}else{const{data:Y}=await o.get("/api/v1/keeper/state/search",{params:{q:f,limit:30}});ae.value=(Y.results||[]).map(U=>({id:U.id,kind:U.kind,snippet:U.snippet,icon:eo(U.kind),color:wt(U.kind),route:"/structure?entry="+U.id}))}}catch{ae.value=[]}finally{Ue.value=!1}}function jt(){ze&&clearTimeout(ze),ze=window.setTimeout(vt,300)}function Nt(f){Te.value=f,vt(),window.setTimeout(()=>{const g=document.querySelector(".global-search-input");g&&(g.focus(),g.setSelectionRange(f.length,f.length))},10)}function It(f){if(we.value=!1,Te.value="",ae.value=[],f.route)if(f.route.includes("?")){const[g,ie]=f.route.split("?"),$=Object.fromEntries(new URLSearchParams(ie));t.push({path:g,query:$})}else t.push(f.route)}function gt(f){(f.ctrlKey||f.metaKey)&&f.shiftKey&&(f.key==="F"||f.key==="f")&&(f.preventDefault(),we.value=!0,setTimeout(()=>document.querySelector(".global-search-input")?.focus(),50)),f.key==="Escape"&&we.value&&(we.value=!1)}function no(){r.logout()}Ne(()=>n.fullPath,()=>{try{const f={page:n.name,path:n.fullPath};n.query.entry&&(f.selected_entry=n.query.entry),n.query.ns&&(f.namespace=n.query.ns),r.setContext(f)}catch{}});function Jt(f){const g=f.target;g.closest(".status-dropdown-wrap")||(F.value=!1),g.closest(".structure-dropdown-wrap")||(ne.value=!1),g.closest(".develop-dropdown-wrap")||(G.value=!1),g.closest(".observe-dropdown-wrap")||(oe.value=!1),g.closest(".settings-dropdown-wrap")||(re.value=!1),g.closest(".agent-dropdown-wrap")||(H.value=!1)}return Ln(()=>{u=i.on("action:navigate",f=>{const g=f?.data?.path||f?.path;g&&t.push(g)}),d=i.on("keeper.logs",f=>{const g=f?.data?.counters||f?.counters;g&&(l.value=g.error||0,a.value=g.warn||0)}),c=i.on("welcome",()=>s.ensureSubscribed(o,!0)),Ct(),p(),At(),v(),s.ensureSubscribed(o,!0),document.addEventListener("click",Jt),document.addEventListener("keydown",gt)}),bo(()=>{c?.(),u?.(),d?.(),document.removeEventListener("click",Jt),document.removeEventListener("keydown",gt)}),(f,g)=>{const ie=Ut("router-view");return T(),L("div",fi,[B("header",bi,[j(V(ct),{variant:"text",class:"shrink-0 !gap-1.5",onClick:g[0]||(g[0]=$=>Be("/"))},{default:Ze(()=>[j(V(X),{icon:"tabler:shield-code",class:"w-4 h-4"}),g[9]||(g[9]=B("span",{class:"text-xs font-bold tracking-wider font-mono"},"KEEPER",-1))]),_:1}),B("nav",vi,[(T(),L(Je,null,Xe(m,$=>j(V(ct),{key:$.name,variant:"text",class:Re(["k-btn-nav relative !gap-1.5",{"k-btn-active":N.value===$.name}]),onClick:Y=>Be($.path)},{default:Ze(()=>[j(V(X),{icon:$.icon,class:"w-3.5 h-3.5"},null,8,["icon"]),Qe(" "+J($.label),1)]),_:2},1032,["class","onClick"])),64)),j(qe,{icon:"tabler:eye",label:"Observe","wrap-class":"observe-dropdown-wrap",items:k.value,open:oe.value,active:ke.value,"current-name":N.value,onToggle:g[1]||(g[1]=$=>oe.value=!oe.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),j(qe,{icon:"tabler:binary-tree",label:"Structure","wrap-class":"structure-dropdown-wrap",items:M.value,open:ne.value,active:ge.value,"current-name":N.value,onToggle:g[2]||(g[2]=$=>ne.value=!ne.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),j(qe,{icon:"tabler:code",label:"Develop","wrap-class":"develop-dropdown-wrap",items:q.value,open:G.value,active:Ee.value,"current-name":N.value,onToggle:g[3]||(g[3]=$=>G.value=!G.value),onNavigate:Oe},null,8,["items","open","active","current-name"]),le.value.length?(T(),De(qe,{key:0,icon:"tabler:heart-rate-monitor",label:"Status","wrap-class":"status-dropdown-wrap",items:le.value,open:F.value,active:ue.value,"current-name":N.value,onToggle:g[4]||(g[4]=$=>F.value=!F.value),onNavigate:Oe},null,8,["items","open","active","current-name"])):ee("",!0),j(qe,{icon:"tabler:settings",label:"Settings","wrap-class":"settings-dropdown-wrap",items:b,open:re.value,active:ft.value,"current-name":N.value,onToggle:g[5]||(g[5]=$=>re.value=!re.value),onNavigate:Oe},null,8,["open","active","current-name"])]),B("div",gi,[j(Qa,{agents:bt.value,open:H.value,onToggle:g[6]||(g[6]=$=>H.value=!H.value),onStart:Lt},null,8,["agents","open"]),j(Xa,{user:Me.value,onLogout:no},null,8,["user"])])]),B("main",hi,[j(ie)]),j(mi,{open:we.value,query:Te.value,results:ae.value,loading:Ue.value,hints:Et,"onUpdate:query":g[7]||(g[7]=$=>Te.value=$),onClose:g[8]||(g[8]=$=>we.value=!1),onSearchInput:jt,onSelect:It,onApplyHint:Nt},null,8,["open","query","results","loading"])])}}}),_i="modulepreload",Si=function(e,t){return new URL(e,t).href},An={},A=function(t,n,o){let r=Promise.resolve();if(n&&n.length>0){let s=function(d){return Promise.all(d.map(c=>Promise.resolve(c).then(p=>({status:"fulfilled",value:p}),p=>({status:"rejected",reason:p}))))};const l=document.getElementsByTagName("link"),a=document.querySelector("meta[property=csp-nonce]"),u=a?.nonce||a?.getAttribute("nonce");r=s(n.map(d=>{if(d=Si(d,o),d in An)return;An[d]=!0;const c=d.endsWith(".css"),p=c?'[rel="stylesheet"]':"";if(!!o)for(let _=l.length-1;_>=0;_--){const h=l[_];if(h.href===d&&(!c||h.rel==="stylesheet"))return}else if(document.querySelector(`link[href="${d}"]${p}`))return;const b=document.createElement("link");if(b.rel=c?"stylesheet":_i,c||(b.as="script"),b.crossOrigin="",b.href=d,u&&b.setAttribute("nonce",u),document.head.appendChild(b),c)return new Promise((_,h)=>{b.addEventListener("load",_),b.addEventListener("error",()=>h(new Error(`Unable to preload CSS for ${d}`)))})}))}function i(s){const l=new Event("vite:preloadError",{cancelable:!0});if(l.payload=s,window.dispatchEvent(l),!l.defaultPrevented)throw s}return r.then(s=>{for(const l of s||[])l.status==="rejected"&&i(l.reason);return t().catch(i)})};function ki(e,t={}){const n=t.host??$t,o=t.on===void 0?So:t.on,r=ho();t.initialPath&&r.replace(t.initialPath);const i=yo({history:r,routes:e});ko(l=>i.resolve(l));let s;return i.afterEach(l=>{const a=s;s=void 0,n.onRouteChanged(l.fullPath,a)}),o&&o("@history",({path:l,navId:a})=>{if(!l)return;a!==void 0&&(s=a);const u=l.startsWith("/")?l:`/${l}`;i.currentRoute.value.fullPath!==u&&i.push(u)}),i}Ae({name:"WippyHostRouterLink",props:{to:{type:String,required:!0}},setup(e,{slots:t}){return()=>Ke("a",{href:e.to,onClick:n=>{n.defaultPrevented||n.button!==0||n.metaKey||n.altKey||n.ctrlKey||n.shiftKey||(n.preventDefault(),$t.navigate(e.to))}},t.default?.())}});Ae({name:"WippyAutoRouterLink",props:{to:{type:[String,Object],required:!0},replace:{type:Boolean,default:!1},activeClass:{type:String,default:void 0},exactActiveClass:{type:String,default:void 0},ariaCurrentValue:{type:String,default:"page"},externalTarget:{type:String,default:"_blank"}},setup(e,{slots:t}){const n=En();return()=>{const o=n.resolve(e.to),r=$t.classifyLink(o.href);if(r.kind==="host-nav")return Ke("a",{href:o.href,onClick:i=>{i.defaultPrevented||i.button===0&&(i.metaKey||i.altKey||i.ctrlKey||i.shiftKey||(i.preventDefault(),$t.navigate(r.normalizedPath??r.href)))},"aria-current":e.ariaCurrentValue},t.default?.());if(r.kind==="external"){const i=e.externalTarget==="_blank";return Ke("a",{href:o.href,target:e.externalTarget||void 0,rel:i?"noopener noreferrer":void 0},t.default?.())}return r.kind==="ignore"?Ke("a",{href:o.href||"#",onClick:i=>i.preventDefault()},t.default?.()):Ke(_o,{to:e.to,replace:e.replace,activeClass:e.activeClass,exactActiveClass:e.exactActiveClass,ariaCurrentValue:e.ariaCurrentValue},t.default?{default:i=>t.default?.(i)}:void 0)}}});const wi=[{path:"/",name:"dashboard",component:()=>A(()=>import("./assets/dashboard-CSK4-BTI.js"),__vite__mapDeps([0,1,2,3,4,5,6,7,8]),import.meta.url)},{path:"/dataflows",name:"workflow",component:()=>A(()=>import("./assets/workflow-BnPrisCC.js"),__vite__mapDeps([9,3]),import.meta.url)},{path:"/sessions",name:"sessions",component:()=>A(()=>import("./assets/sessions-BrMpENKd.js"),__vite__mapDeps([10,11]),import.meta.url)},{path:"/session/:id",name:"session-detail",component:()=>A(()=>import("./assets/session-detail-CDshxVJR.js"),__vite__mapDeps([12,1,13,14,15]),import.meta.url)},{path:"/agents",name:"agents",component:()=>A(()=>import("./assets/agents-Pl02yESY.js"),__vite__mapDeps([16,1,8,17,14,15,11]),import.meta.url)},{path:"/models",name:"models",component:()=>A(()=>import("./assets/models-B3DPFv9Z.js"),__vite__mapDeps([18,1,8,17,14,15,11]),import.meta.url)},{path:"/tools",name:"tools",component:()=>A(()=>import("./assets/tools-page-D8Jt7la8.js"),__vite__mapDeps([19,1,8,17,14,15,11]),import.meta.url)},{path:"/traits",name:"traits",component:()=>A(()=>import("./assets/traits-BW2MPbA7.js"),__vite__mapDeps([20,1,8,17,14,15,11]),import.meta.url)},{path:"/endpoints",name:"endpoints",component:()=>A(()=>import("./assets/endpoints-B9BCTqnt.js"),__vite__mapDeps([21,1,17,14,15,11]),import.meta.url)},{path:"/policies",name:"policies",component:()=>A(()=>import("./assets/policies-BgLUSNmY.js"),__vite__mapDeps([22,1,8,17,14,15,11]),import.meta.url)},{path:"/structure",name:"structure",component:()=>A(()=>import("./assets/structure-BoeDRm0U.js"),__vite__mapDeps([23,8]),import.meta.url)},{path:"/dataflow/:id",name:"dataflow-detail",component:()=>A(()=>import("./assets/dataflow-detail-CBigbUg1.js"),__vite__mapDeps([24,1,3,13,15]),import.meta.url)},{path:"/plugin/:id",name:"plugin",component:()=>A(()=>import("./assets/plugin-page-78CA4jh7.js"),__vite__mapDeps([25,26]),import.meta.url)},{path:"/logs",name:"logs",component:()=>A(()=>import("./assets/logger-CJ4vPYnn.js"),__vite__mapDeps([27,6,11]),import.meta.url)},{path:"/activity",name:"activity",component:()=>A(()=>import("./assets/activity-BTPuvvNP.js"),__vite__mapDeps([28,11]),import.meta.url)},{path:"/system",name:"system",component:()=>A(()=>import("./assets/system-Ba_7tip8.js"),__vite__mapDeps([29,2,11]),import.meta.url)},{path:"/tests",name:"tests",component:()=>A(()=>import("./assets/tests-C21pmcDl.js"),__vite__mapDeps([30,8]),import.meta.url)},{path:"/settings",name:"settings",component:()=>A(()=>import("./assets/settings-86u394KL.js"),__vite__mapDeps([31,11]),import.meta.url)},{path:"/settings/environment",name:"settings-environment",component:()=>A(()=>import("./assets/settings-environment-DV741d7r.js"),__vite__mapDeps([32,11]),import.meta.url)},{path:"/settings/registry",name:"settings-registry",component:()=>A(()=>import("./assets/settings-registry-CUu_UwsG.js"),__vite__mapDeps([33,11]),import.meta.url)},{path:"/settings/hub",name:"settings-hub",component:()=>A(()=>import("./assets/settings-hub-y1XekLoM.js"),__vite__mapDeps([34,1,35,11]),import.meta.url)},{path:"/settings/hub/:org/:name",name:"settings-hub-module",component:()=>A(()=>import("./assets/settings-hub-module-CFfP-n46.js"),__vite__mapDeps([36,1,35]),import.meta.url)},{path:"/knowledge",name:"knowledge",component:()=>A(()=>import("./assets/knowledge-B7f2toOe.js"),__vite__mapDeps([37,7,13]),import.meta.url)},{path:"/mcp",name:"mcp",component:()=>A(()=>import("./assets/mcp-xa6ZkHDG.js"),[],import.meta.url)},{path:"/components",name:"components",component:()=>A(()=>import("./assets/components-C4F7M12i.js"),__vite__mapDeps([38,13,15]),import.meta.url)},{path:"/tasks",name:"tasks",component:()=>A(()=>import("./assets/tasks-C61-GdIs.js"),__vite__mapDeps([39,4]),import.meta.url)},{path:"/tasks/:id",name:"task-detail",component:()=>A(()=>import("./assets/task-detail-_SqHbZ-7.js"),__vite__mapDeps([40,1,4,13]),import.meta.url)},{path:"/changes",name:"changes",component:()=>A(()=>import("./assets/changes-CQL3LW9V.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/changes/:id",name:"changes-detail",component:()=>A(()=>import("./assets/changes-CQL3LW9V.js"),__vite__mapDeps([41,1,5,26]),import.meta.url)},{path:"/audit",name:"audit",component:()=>A(()=>import("./assets/audit-CZqtKQmG.js"),[],import.meta.url)},{path:"/:pathMatch(.*)*",name:"not-found",redirect:"/"}];function $i(e,t,n){return ki(wi,{initialPath:n,host:e,on:t})}async function Pi(){const e=await window.$W.config(),t=await window.$W.host(),n=await window.$W.api(),o=await window.$W.instance();n.interceptors.response.use(u=>u,u=>(u?.response?.status===401&&t.handleError("auth-expired",{url:u?.config?.url,method:u?.config?.method,message:u?.message}),Promise.reject(u)));let r=null;try{r=await window.$W.on()}catch{}const i=e.context?.route||"/",s=e.theming?.global?.icons??e.theming?.global?.iconSets?.custom;s&&oo({prefix:"custom",icons:s});const l=vo(yi);l.use(ro()),l.use(Or),l.provide(Yn,t),l.provide(Qn,n),l.provide(Zn,o),l.provide(xa,e),r&&l.provide(Ca,r);const a=$i(t,o.on,i);return l.use(a),l}async function Oi(e="#app"){const t=await Pi();return t.mount(e),t}Oi();export{Hi as A,Ki as B,zi as C,D,Ei as E,Qt as F,Ye as G,to as _,Gn as a,ji as b,Fi as c,Ea as d,Zi as e,Qi as f,Bi as g,Yi as h,Gi as i,Aa as j,Ii as k,Ni as l,A as m,wt as n,eo as o,Ui as p,Di as q,Ri as r,ct as s,Cn as t,La as u,Ra as v,Vi as w,Mi as x,Wi as y,qi as z};
