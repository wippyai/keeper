import{openBlock as l,createElementBlock as d,mergeProps as w,createElementVNode as f,renderSlot as _,createBlock as G,Teleport as nn,createCommentVNode as y,computed as Y,resolveComponent as le,resolveDirective as ht,withCtx as ne,createVNode as K,Transition as gt,withDirectives as Se,Fragment as J,normalizeClass as ee,toDisplayString as v,resolveDynamicComponent as Ie,createTextVNode as F,renderList as re,normalizeStyle as An,createSlots as Dn,defineComponent as Ke,ref as W,watch as on,onBeforeUnmount as Vn,unref as N,withKeys as rt,withModifiers as Tn,useId as Vt,shallowRef as we,vModelText as Tt,vModelCheckbox as Bn}from"vue";import{D as He,F as he,L as Fn,G as ie,H as ze,I as Rn,U as jn,J as Bt,K as fe,M as Kn,N as Hn,O as sn,P as Nn,s as Un,R as vt,Q as Ne,S as me,T as an,V as Wn,W as Gn,X as rn,Y as Zn,Z as Yn,$ as Xn,a0 as Jn,a1 as ln,a2 as un,a3 as Ft,a4 as Le,a5 as _e,a6 as lt,a7 as Qn,a8 as qn,a9 as ei,aa as ti,ab as ni,ac as Pe,u as dn,l as ii,_ as cn}from"../app.js";import{Icon as ae}from"@iconify/vue";function oi(){let t=[],e=(c,p,m=999)=>{let g=s(c,p,m),h=g.value+(g.key===c?0:m)+1;return t.push({key:c,value:h}),h},n=c=>{t=t.filter(p=>p.value!==c)},i=(c,p)=>s(c).value,s=(c,p,m=0)=>[...t].reverse().find(g=>!0)||{key:c,value:m},o=c=>c&&parseInt(c.style.zIndex,10)||0;return{get:o,set:(c,p,m)=>{p&&(p.style.zIndex=String(e(c,!0,m)))},clear:c=>{c&&(n(o(c)),c.style.zIndex="")},getCurrent:c=>i(c)}}var ke=oi();function Ee(t){const e=t.response?.data;return{code:e?.code,message:e?.error||e?.message||t.message||"Request failed",details:e?.details}}function si(){return{removed:[],kept:[],kept_under_uncertainty:[],warnings:[]}}async function ai(t,e={}){const n={};e.component&&(n.component=e.component),e.entries===!1&&(n.entries=!1),e.migrations===!1&&(n.migrations=!1),e.modules===!1&&(n.modules=!1);const{data:i}=await t.get("/api/v1/keeper/hub/dependencies",{params:n});return i}function ri(t){const e=t?.warnings;return Array.isArray(e)?e.filter(n=>n&&typeof n.message=="string"):[]}async function li(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/install",e);return n}async function ui(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/plan",e);return n}async function di(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/fill-gaps",e);return n}async function Cr(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/uninstall",e);return n}async function Sr(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/dependencies/uninstall",{...e,dry_run:!0}),i=n?.preview;return i?{removed:i.removed||[],kept:i.kept||[],kept_under_uncertainty:i.kept_under_uncertainty||[],warnings:i.warnings||[]}:si()}async function ci(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/scan",e);return n}async function kr(t,e={}){const n={};e.component&&(n.component=e.component),e.entry_ids&&e.entry_ids.length&&(n.entry_ids=e.entry_ids.join(","));const{data:i}=await t.get("/api/v1/keeper/hub/migrations",{params:n});return i}async function Ir(t,e){const{data:n}=await t.post("/api/v1/keeper/hub/migrations/run",e);return n}const pn="https://hub.wippy.ai/";function pi(t){const e=(t||"").trim();return/^https?:\/\/[^/]/i.test(e)?e.endsWith("/")?e:`${e}/`:pn}function Or(t){try{return new URL(t).host}catch{return t}}async function xr(t){try{const{data:e}=await t.get("/api/v1/keeper/hub/registry");return pi(e?.success?e.registry:"")}catch{return pn}}async function $r(t,e={}){const n={};e.query&&(n.q=e.query),e.page&&(n.page=e.page),e.page_size&&(n.page_size=e.page_size),e.visibility&&(n.visibility=e.visibility),e.type&&(n.type=e.type),e.sort&&(n.sort=e.sort);const{data:i}=await t.get("/api/v1/keeper/hub/browse",{params:n});return i}async function zr(t,e,n={}){const i={module:e};n.page&&(i.page=n.page),n.page_size&&(i.page_size=n.page_size);const{data:s}=await t.get("/api/v1/keeper/hub/versions",{params:i});return s}async function Lr(t,e,n){const i={module:e},{data:s}=await t.get("/api/v1/keeper/hub/readme",{params:i});return s}var et={name:"TimesIcon",extends:He};function fi(t){return vi(t)||gi(t)||hi(t)||mi()}function mi(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function hi(t,e){if(t){if(typeof t=="string")return ut(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ut(t,e):void 0}}function gi(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function vi(t){if(Array.isArray(t))return ut(t)}function ut(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function yi(t,e,n,i,s,o){return l(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),fi(e[0]||(e[0]=[f("path",{d:"M8.01186 7.00933L12.27 2.75116C12.341 2.68501 12.398 2.60524 12.4375 2.51661C12.4769 2.42798 12.4982 2.3323 12.4999 2.23529C12.5016 2.13827 12.4838 2.0419 12.4474 1.95194C12.4111 1.86197 12.357 1.78024 12.2884 1.71163C12.2198 1.64302 12.138 1.58893 12.0481 1.55259C11.9581 1.51625 11.8617 1.4984 11.7647 1.50011C11.6677 1.50182 11.572 1.52306 11.4834 1.56255C11.3948 1.60204 11.315 1.65898 11.2488 1.72997L6.99067 5.98814L2.7325 1.72997C2.59553 1.60234 2.41437 1.53286 2.22718 1.53616C2.03999 1.53946 1.8614 1.61529 1.72901 1.74767C1.59663 1.88006 1.5208 2.05865 1.5175 2.24584C1.5142 2.43303 1.58368 2.61419 1.71131 2.75116L5.96948 7.00933L1.71131 11.2675C1.576 11.403 1.5 11.5866 1.5 11.7781C1.5 11.9696 1.576 12.1532 1.71131 12.2887C1.84679 12.424 2.03043 12.5 2.2219 12.5C2.41338 12.5 2.59702 12.424 2.7325 12.2887L6.99067 8.03052L11.2488 12.2887C11.3843 12.424 11.568 12.5 11.7594 12.5C11.9509 12.5 12.1346 12.424 12.27 12.2887C12.4053 12.1532 12.4813 11.9696 12.4813 11.7781C12.4813 11.5866 12.4053 11.403 12.27 11.2675L8.01186 7.00933Z",fill:"currentColor"},null,-1)])),16)}et.render=yi;var fn={name:"WindowMaximizeIcon",extends:He};function bi(t){return ki(t)||Si(t)||Ci(t)||wi()}function wi(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Ci(t,e){if(t){if(typeof t=="string")return dt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?dt(t,e):void 0}}function Si(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function ki(t){if(Array.isArray(t))return dt(t)}function dt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function Ii(t,e,n,i,s,o){return l(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),bi(e[0]||(e[0]=[f("path",{"fill-rule":"evenodd","clip-rule":"evenodd",d:"M7 14H11.8C12.3835 14 12.9431 13.7682 13.3556 13.3556C13.7682 12.9431 14 12.3835 14 11.8V2.2C14 1.61652 13.7682 1.05694 13.3556 0.644365C12.9431 0.231785 12.3835 0 11.8 0H2.2C1.61652 0 1.05694 0.231785 0.644365 0.644365C0.231785 1.05694 0 1.61652 0 2.2V7C0 7.15913 0.063214 7.31174 0.175736 7.42426C0.288258 7.53679 0.44087 7.6 0.6 7.6C0.75913 7.6 0.911742 7.53679 1.02426 7.42426C1.13679 7.31174 1.2 7.15913 1.2 7V2.2C1.2 1.93478 1.30536 1.68043 1.49289 1.49289C1.68043 1.30536 1.93478 1.2 2.2 1.2H11.8C12.0652 1.2 12.3196 1.30536 12.5071 1.49289C12.6946 1.68043 12.8 1.93478 12.8 2.2V11.8C12.8 12.0652 12.6946 12.3196 12.5071 12.5071C12.3196 12.6946 12.0652 12.8 11.8 12.8H7C6.84087 12.8 6.68826 12.8632 6.57574 12.9757C6.46321 13.0883 6.4 13.2409 6.4 13.4C6.4 13.5591 6.46321 13.7117 6.57574 13.8243C6.68826 13.9368 6.84087 14 7 14ZM9.77805 7.42192C9.89013 7.534 10.0415 7.59788 10.2 7.59995C10.3585 7.59788 10.5099 7.534 10.622 7.42192C10.7341 7.30985 10.798 7.15844 10.8 6.99995V3.94242C10.8066 3.90505 10.8096 3.86689 10.8089 3.82843C10.8079 3.77159 10.7988 3.7157 10.7824 3.6623C10.756 3.55552 10.701 3.45698 10.622 3.37798C10.5099 3.2659 10.3585 3.20202 10.2 3.19995H7.00002C6.84089 3.19995 6.68828 3.26317 6.57576 3.37569C6.46324 3.48821 6.40002 3.64082 6.40002 3.79995C6.40002 3.95908 6.46324 4.11169 6.57576 4.22422C6.68828 4.33674 6.84089 4.39995 7.00002 4.39995H8.80006L6.19997 7.00005C6.10158 7.11005 6.04718 7.25246 6.04718 7.40005C6.04718 7.54763 6.10158 7.69004 6.19997 7.80005C6.30202 7.91645 6.44561 7.98824 6.59997 8.00005C6.75432 7.98824 6.89791 7.91645 6.99997 7.80005L9.60002 5.26841V6.99995C9.6021 7.15844 9.66598 7.30985 9.77805 7.42192ZM1.4 14H3.8C4.17066 13.9979 4.52553 13.8498 4.78763 13.5877C5.04973 13.3256 5.1979 12.9707 5.2 12.6V10.2C5.1979 9.82939 5.04973 9.47452 4.78763 9.21242C4.52553 8.95032 4.17066 8.80215 3.8 8.80005H1.4C1.02934 8.80215 0.674468 8.95032 0.412371 9.21242C0.150274 9.47452 0.00210008 9.82939 0 10.2V12.6C0.00210008 12.9707 0.150274 13.3256 0.412371 13.5877C0.674468 13.8498 1.02934 13.9979 1.4 14ZM1.25858 10.0586C1.29609 10.0211 1.34696 10 1.4 10H3.8C3.85304 10 3.90391 10.0211 3.94142 10.0586C3.97893 10.0961 4 10.147 4 10.2V12.6C4 12.6531 3.97893 12.704 3.94142 12.7415C3.90391 12.779 3.85304 12.8 3.8 12.8H1.4C1.34696 12.8 1.29609 12.779 1.25858 12.7415C1.22107 12.704 1.2 12.6531 1.2 12.6V10.2C1.2 10.147 1.22107 10.0961 1.25858 10.0586Z",fill:"currentColor"},null,-1)])),16)}fn.render=Ii;var mn={name:"WindowMinimizeIcon",extends:He};function Oi(t){return Li(t)||zi(t)||$i(t)||xi()}function xi(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function $i(t,e){if(t){if(typeof t=="string")return ct(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ct(t,e):void 0}}function zi(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function Li(t){if(Array.isArray(t))return ct(t)}function ct(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function _i(t,e,n,i,s,o){return l(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),Oi(e[0]||(e[0]=[f("path",{"fill-rule":"evenodd","clip-rule":"evenodd",d:"M11.8 0H2.2C1.61652 0 1.05694 0.231785 0.644365 0.644365C0.231785 1.05694 0 1.61652 0 2.2V7C0 7.15913 0.063214 7.31174 0.175736 7.42426C0.288258 7.53679 0.44087 7.6 0.6 7.6C0.75913 7.6 0.911742 7.53679 1.02426 7.42426C1.13679 7.31174 1.2 7.15913 1.2 7V2.2C1.2 1.93478 1.30536 1.68043 1.49289 1.49289C1.68043 1.30536 1.93478 1.2 2.2 1.2H11.8C12.0652 1.2 12.3196 1.30536 12.5071 1.49289C12.6946 1.68043 12.8 1.93478 12.8 2.2V11.8C12.8 12.0652 12.6946 12.3196 12.5071 12.5071C12.3196 12.6946 12.0652 12.8 11.8 12.8H7C6.84087 12.8 6.68826 12.8632 6.57574 12.9757C6.46321 13.0883 6.4 13.2409 6.4 13.4C6.4 13.5591 6.46321 13.7117 6.57574 13.8243C6.68826 13.9368 6.84087 14 7 14H11.8C12.3835 14 12.9431 13.7682 13.3556 13.3556C13.7682 12.9431 14 12.3835 14 11.8V2.2C14 1.61652 13.7682 1.05694 13.3556 0.644365C12.9431 0.231785 12.3835 0 11.8 0ZM6.368 7.952C6.44137 7.98326 6.52025 7.99958 6.6 8H9.8C9.95913 8 10.1117 7.93678 10.2243 7.82426C10.3368 7.71174 10.4 7.55913 10.4 7.4C10.4 7.24087 10.3368 7.08826 10.2243 6.97574C10.1117 6.86321 9.95913 6.8 9.8 6.8H8.048L10.624 4.224C10.73 4.11026 10.7877 3.95982 10.7849 3.80438C10.7822 3.64894 10.7192 3.50063 10.6093 3.3907C10.4994 3.28077 10.3511 3.2178 10.1956 3.21506C10.0402 3.21232 9.88974 3.27002 9.776 3.376L7.2 5.952V4.2C7.2 4.04087 7.13679 3.88826 7.02426 3.77574C6.91174 3.66321 6.75913 3.6 6.6 3.6C6.44087 3.6 6.28826 3.66321 6.17574 3.77574C6.06321 3.88826 6 4.04087 6 4.2V7.4C6.00042 7.47975 6.01674 7.55862 6.048 7.632C6.07656 7.70442 6.11971 7.7702 6.17475 7.82524C6.2298 7.88029 6.29558 7.92344 6.368 7.952ZM1.4 8.80005H3.8C4.17066 8.80215 4.52553 8.95032 4.78763 9.21242C5.04973 9.47452 5.1979 9.82939 5.2 10.2V12.6C5.1979 12.9707 5.04973 13.3256 4.78763 13.5877C4.52553 13.8498 4.17066 13.9979 3.8 14H1.4C1.02934 13.9979 0.674468 13.8498 0.412371 13.5877C0.150274 13.3256 0.00210008 12.9707 0 12.6V10.2C0.00210008 9.82939 0.150274 9.47452 0.412371 9.21242C0.674468 8.95032 1.02934 8.80215 1.4 8.80005ZM3.94142 12.7415C3.97893 12.704 4 12.6531 4 12.6V10.2C4 10.147 3.97893 10.0961 3.94142 10.0586C3.90391 10.0211 3.85304 10 3.8 10H1.4C1.34696 10 1.29609 10.0211 1.25858 10.0586C1.22107 10.0961 1.2 10.147 1.2 10.2V12.6C1.2 12.6531 1.22107 12.704 1.25858 12.7415C1.29609 12.779 1.34696 12.8 1.4 12.8H3.8C3.85304 12.8 3.90391 12.779 3.94142 12.7415Z",fill:"currentColor"},null,-1)])),16)}mn.render=_i;var Pi=he.extend({name:"focustrap-directive"}),Ei=Rn.extend({style:Pi});function Ae(t){"@babel/helpers - typeof";return Ae=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Ae(t)}function Rt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function jt(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Rt(Object(n),!0).forEach(function(i){Mi(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Rt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function Mi(t,e,n){return(e=Ai(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Ai(t){var e=Di(t,"string");return Ae(e)=="symbol"?e:e+""}function Di(t,e){if(Ae(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Ae(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Vi=Ei.extend("focustrap",{mounted:function(e,n){var i=n.value||{},s=i.disabled;s||(this.createHiddenFocusableElements(e,n),this.bind(e,n),this.autoElementFocus(e,n)),e.setAttribute("data-pd-focustrap",!0),this.$el=e},updated:function(e,n){var i=n.value||{},s=i.disabled;s&&this.unbind(e)},unmounted:function(e){this.unbind(e)},methods:{getComputedSelector:function(e){return':not(.p-hidden-focusable):not([data-p-hidden-focusable="true"])'.concat(e??"")},bind:function(e,n){var i=this,s=n.value||{},o=s.onFocusIn,c=s.onFocusOut;e.$_pfocustrap_mutationobserver=new MutationObserver(function(p){p.forEach(function(m){if(m.type==="childList"&&!e.contains(document.activeElement)){var g=function(b){var S=Bt(b)?Bt(b,i.getComputedSelector(e.$_pfocustrap_focusableselector))?b:ze(e,i.getComputedSelector(e.$_pfocustrap_focusableselector)):ze(b);return fe(S)?S:b.nextSibling&&g(b.nextSibling)};ie(g(m.nextSibling))}})}),e.$_pfocustrap_mutationobserver.disconnect(),e.$_pfocustrap_mutationobserver.observe(e,{childList:!0}),e.$_pfocustrap_focusinlistener=function(p){return o&&o(p)},e.$_pfocustrap_focusoutlistener=function(p){return c&&c(p)},e.addEventListener("focusin",e.$_pfocustrap_focusinlistener),e.addEventListener("focusout",e.$_pfocustrap_focusoutlistener)},unbind:function(e){e.$_pfocustrap_mutationobserver&&e.$_pfocustrap_mutationobserver.disconnect(),e.$_pfocustrap_focusinlistener&&e.removeEventListener("focusin",e.$_pfocustrap_focusinlistener)&&(e.$_pfocustrap_focusinlistener=null),e.$_pfocustrap_focusoutlistener&&e.removeEventListener("focusout",e.$_pfocustrap_focusoutlistener)&&(e.$_pfocustrap_focusoutlistener=null)},autoFocus:function(e){this.autoElementFocus(this.$el,{value:jt(jt({},e),{},{autoFocus:!0})})},autoElementFocus:function(e,n){var i=n.value||{},s=i.autoFocusSelector,o=s===void 0?"":s,c=i.firstFocusableSelector,p=c===void 0?"":c,m=i.autoFocus,g=m===void 0?!1:m,h=ze(e,"[autofocus]".concat(this.getComputedSelector(o)));g&&!h&&(h=ze(e,this.getComputedSelector(p))),ie(h)},onFirstHiddenElementFocus:function(e){var n,i=e.currentTarget,s=e.relatedTarget,o=s===i.$_pfocustrap_lasthiddenfocusableelement||!((n=this.$el)!==null&&n!==void 0&&n.contains(s))?ze(i.parentElement,this.getComputedSelector(i.$_pfocustrap_focusableselector)):i.$_pfocustrap_lasthiddenfocusableelement;ie(o)},onLastHiddenElementFocus:function(e){var n,i=e.currentTarget,s=e.relatedTarget,o=s===i.$_pfocustrap_firsthiddenfocusableelement||!((n=this.$el)!==null&&n!==void 0&&n.contains(s))?Fn(i.parentElement,this.getComputedSelector(i.$_pfocustrap_focusableselector)):i.$_pfocustrap_firsthiddenfocusableelement;ie(o)},createHiddenFocusableElements:function(e,n){var i=this,s=n.value||{},o=s.tabIndex,c=o===void 0?0:o,p=s.firstFocusableSelector,m=p===void 0?"":p,g=s.lastFocusableSelector,h=g===void 0?"":g,b=function(L){return jn("span",{class:"p-hidden-accessible p-hidden-focusable",tabIndex:c,role:"presentation","aria-hidden":!0,"data-p-hidden-accessible":!0,"data-p-hidden-focusable":!0,onFocus:L?.bind(i)})},S=b(this.onFirstHiddenElementFocus),C=b(this.onLastHiddenElementFocus);S.$_pfocustrap_lasthiddenfocusableelement=C,S.$_pfocustrap_focusableselector=m,S.setAttribute("data-pc-section","firstfocusableelement"),C.$_pfocustrap_firsthiddenfocusableelement=S,C.$_pfocustrap_focusableselector=h,C.setAttribute("data-pc-section","lastfocusableelement"),e.prepend(S),e.append(C)}}}),yt={name:"Portal",props:{appendTo:{type:[String,Object],default:"body"},disabled:{type:Boolean,default:!1}},data:function(){return{mounted:!1}},mounted:function(){this.mounted=Kn()},computed:{inline:function(){return this.disabled||this.appendTo==="self"}}};function Ti(t,e,n,i,s,o){return o.inline?_(t.$slots,"default",{key:0}):s.mounted?(l(),G(nn,{key:1,to:n.appendTo},[_(t.$slots,"default")],8,["to"])):y("",!0)}yt.render=Ti;function Kt(){Nn({variableName:sn("scrollbar.width").name})}function Ht(){Hn({variableName:sn("scrollbar.width").name})}var Bi=`
    .p-dialog {
        max-height: 90%;
        transform: scale(1);
        border-radius: dt('dialog.border.radius');
        box-shadow: dt('dialog.shadow');
        background: dt('dialog.background');
        border: 1px solid dt('dialog.border.color');
        color: dt('dialog.color');
        will-change: transform;
    }

    .p-dialog-content {
        overflow-y: auto;
        padding: dt('dialog.content.padding');
        flex-grow: 1;
    }

    .p-dialog-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-shrink: 0;
        padding: dt('dialog.header.padding');
    }

    .p-dialog-title {
        font-weight: dt('dialog.title.font.weight');
        font-size: dt('dialog.title.font.size');
    }

    .p-dialog-footer {
        flex-shrink: 0;
        padding: dt('dialog.footer.padding');
        display: flex;
        justify-content: flex-end;
        gap: dt('dialog.footer.gap');
    }

    .p-dialog-header-actions {
        display: flex;
        align-items: center;
        gap: dt('dialog.header.gap');
    }

    .p-dialog-top .p-dialog,
    .p-dialog-bottom .p-dialog,
    .p-dialog-left .p-dialog,
    .p-dialog-right .p-dialog,
    .p-dialog-topleft .p-dialog,
    .p-dialog-topright .p-dialog,
    .p-dialog-bottomleft .p-dialog,
    .p-dialog-bottomright .p-dialog {
        margin: 1rem;
    }

    .p-dialog-maximized {
        width: 100vw !important;
        height: 100vh !important;
        top: 0px !important;
        left: 0px !important;
        max-height: 100%;
        height: 100%;
        border-radius: 0;
    }

    .p-dialog .p-resizable-handle {
        position: absolute;
        font-size: 0.1px;
        display: block;
        cursor: se-resize;
        width: 12px;
        height: 12px;
        right: 1px;
        bottom: 1px;
    }

    .p-dialog-enter-active {
        animation: p-animate-dialog-enter 300ms cubic-bezier(.19,1,.22,1);
    }

    .p-dialog-leave-active {
        animation: p-animate-dialog-leave 300ms cubic-bezier(.19,1,.22,1);
    }

    @keyframes p-animate-dialog-enter {
        from {
            opacity: 0;
            transform: scale(0.93);
        }
    }

    @keyframes p-animate-dialog-leave {
        to {
            opacity: 0;
            transform: scale(0.93);
        }
    }
`,Fi={mask:function(e){var n=e.position,i=e.modal;return{position:"fixed",height:"100%",width:"100%",left:0,top:0,display:"flex",justifyContent:n==="left"||n==="topleft"||n==="bottomleft"?"flex-start":n==="right"||n==="topright"||n==="bottomright"?"flex-end":"center",alignItems:n==="top"||n==="topleft"||n==="topright"?"flex-start":n==="bottom"||n==="bottomleft"||n==="bottomright"?"flex-end":"center",pointerEvents:i?"auto":"none"}},root:{display:"flex",flexDirection:"column",pointerEvents:"auto"}},Ri={mask:function(e){var n=e.props,i=["left","right","top","topleft","topright","bottom","bottomleft","bottomright"],s=i.find(function(o){return o===n.position});return["p-dialog-mask",{"p-overlay-mask p-overlay-mask-enter-active":n.modal},s?"p-dialog-".concat(s):""]},root:function(e){var n=e.props,i=e.instance;return["p-dialog p-component",{"p-dialog-maximized":n.maximizable&&i.maximized}]},header:"p-dialog-header",title:"p-dialog-title",headerActions:"p-dialog-header-actions",pcMaximizeButton:"p-dialog-maximize-button",pcCloseButton:"p-dialog-close-button",content:"p-dialog-content",footer:"p-dialog-footer"},ji=he.extend({name:"dialog",style:Bi,classes:Ri,inlineStyles:Fi}),Ki={name:"BaseDialog",extends:Ne,props:{header:{type:null,default:null},footer:{type:null,default:null},visible:{type:Boolean,default:!1},modal:{type:Boolean,default:null},contentStyle:{type:null,default:null},contentClass:{type:String,default:null},contentProps:{type:null,default:null},maximizable:{type:Boolean,default:!1},dismissableMask:{type:Boolean,default:!1},closable:{type:Boolean,default:!0},closeOnEscape:{type:Boolean,default:!0},showHeader:{type:Boolean,default:!0},blockScroll:{type:Boolean,default:!1},baseZIndex:{type:Number,default:0},autoZIndex:{type:Boolean,default:!0},position:{type:String,default:"center"},breakpoints:{type:Object,default:null},draggable:{type:Boolean,default:!0},keepInViewport:{type:Boolean,default:!0},minX:{type:Number,default:0},minY:{type:Number,default:0},appendTo:{type:[String,Object],default:"body"},closeIcon:{type:String,default:void 0},maximizeIcon:{type:String,default:void 0},minimizeIcon:{type:String,default:void 0},closeButtonProps:{type:Object,default:function(){return{severity:"secondary",text:!0,rounded:!0}}},maximizeButtonProps:{type:Object,default:function(){return{severity:"secondary",text:!0,rounded:!0}}},_instance:null},style:ji,provide:function(){return{$pcDialog:this,$parentInstance:this}}},hn={name:"Dialog",extends:Ki,inheritAttrs:!1,emits:["update:visible","show","hide","after-hide","maximize","unmaximize","dragstart","dragend"],provide:function(){var e=this;return{dialogRef:Y(function(){return e._instance})}},data:function(){return{containerVisible:this.visible,maximized:!1,focusableMax:null,focusableClose:null,target:null}},documentKeydownListener:null,container:null,mask:null,content:null,headerContainer:null,footerContainer:null,maximizableButton:null,closeButton:null,styleElement:null,dragging:null,documentDragListener:null,documentDragEndListener:null,lastPageX:null,lastPageY:null,maskMouseDownTarget:null,updated:function(){this.visible&&(this.containerVisible=this.visible)},beforeUnmount:function(){this.unbindDocumentState(),this.unbindGlobalListeners(),this.destroyStyle(),this.mask&&this.autoZIndex&&ke.clear(this.mask),this.container=null,this.mask=null},mounted:function(){this.breakpoints&&this.createStyle()},methods:{close:function(){this.$emit("update:visible",!1)},onEnter:function(){this.$emit("show"),this.target=document.activeElement,this.enableDocumentSettings(),this.bindGlobalListeners(),this.autoZIndex&&ke.set("modal",this.mask,this.baseZIndex||this.$primevue.config.zIndex.modal)},onAfterEnter:function(){this.focus()},onBeforeLeave:function(){this.modal&&!this.isUnstyled&&Yn(this.mask,"p-overlay-mask-leave-active"),this.dragging&&this.documentDragEndListener&&this.documentDragEndListener()},onLeave:function(){this.$emit("hide"),ie(this.target),this.target=null,this.focusableClose=null,this.focusableMax=null},onAfterLeave:function(){this.autoZIndex&&ke.clear(this.mask),this.containerVisible=!1,this.unbindDocumentState(),this.unbindGlobalListeners(),this.$emit("after-hide")},onMaskMouseDown:function(e){this.maskMouseDownTarget=e.target},onMaskMouseUp:function(){this.dismissableMask&&this.modal&&this.mask===this.maskMouseDownTarget&&this.close()},focus:function(){var e=function(s){return s&&s.querySelector("[autofocus]")},n=this.$slots.footer&&e(this.footerContainer);n||(n=this.$slots.header&&e(this.headerContainer),n||(n=this.$slots.default&&e(this.content),n||(this.maximizable?(this.focusableMax=!0,n=this.maximizableButton):(this.focusableClose=!0,n=this.closeButton)))),n&&ie(n,{focusVisible:!0})},maximize:function(e){this.maximized?(this.maximized=!1,this.$emit("unmaximize",e)):(this.maximized=!0,this.$emit("maximize",e)),this.modal||(this.maximized?Kt():Ht())},enableDocumentSettings:function(){(this.modal||!this.modal&&this.blockScroll||this.maximizable&&this.maximized)&&Kt()},unbindDocumentState:function(){(this.modal||!this.modal&&this.blockScroll||this.maximizable&&this.maximized)&&Ht()},onKeyDown:function(e){e.code==="Escape"&&this.closeOnEscape&&!e.isComposing&&this.close()},bindDocumentKeyDownListener:function(){this.documentKeydownListener||(this.documentKeydownListener=this.onKeyDown.bind(this),window.document.addEventListener("keydown",this.documentKeydownListener))},unbindDocumentKeyDownListener:function(){this.documentKeydownListener&&(window.document.removeEventListener("keydown",this.documentKeydownListener),this.documentKeydownListener=null)},containerRef:function(e){this.container=e},maskRef:function(e){this.mask=e},contentRef:function(e){this.content=e},headerContainerRef:function(e){this.headerContainer=e},footerContainerRef:function(e){this.footerContainer=e},maximizableRef:function(e){this.maximizableButton=e?e.$el:void 0},closeButtonRef:function(e){this.closeButton=e?e.$el:void 0},createStyle:function(){if(!this.styleElement&&!this.isUnstyled){var e;this.styleElement=document.createElement("style"),this.styleElement.type="text/css",Zn(this.styleElement,"nonce",(e=this.$primevue)===null||e===void 0||(e=e.config)===null||e===void 0||(e=e.csp)===null||e===void 0?void 0:e.nonce),document.head.appendChild(this.styleElement);var n="";for(var i in this.breakpoints)n+=`
                        @media screen and (max-width: `.concat(i,`) {
                            .p-dialog[`).concat(this.$attrSelector,`] {
                                width: `).concat(this.breakpoints[i],` !important;
                            }
                        }
                    `);this.styleElement.innerHTML=n}},destroyStyle:function(){this.styleElement&&(document.head.removeChild(this.styleElement),this.styleElement=null)},initDrag:function(e){e.target.closest("div").getAttribute("data-pc-section")!=="headeractions"&&this.draggable&&(this.dragging=!0,this.lastPageX=e.pageX,this.lastPageY=e.pageY,this.container.style.margin="0",document.body.setAttribute("data-p-unselectable-text","true"),!this.isUnstyled&&rn(document.body,{"user-select":"none"}),this.$emit("dragstart",e))},bindGlobalListeners:function(){this.draggable&&(this.bindDocumentDragListener(),this.bindDocumentDragEndListener()),this.closeOnEscape&&this.bindDocumentKeyDownListener()},unbindGlobalListeners:function(){this.unbindDocumentDragListener(),this.unbindDocumentDragEndListener(),this.unbindDocumentKeyDownListener()},bindDocumentDragListener:function(){var e=this;this.documentDragListener=function(n){if(e.dragging){var i=an(e.container),s=Wn(e.container),o=n.pageX-e.lastPageX,c=n.pageY-e.lastPageY,p=e.container.getBoundingClientRect(),m=p.left+o,g=p.top+c,h=Gn(),b=getComputedStyle(e.container),S=parseFloat(b.marginLeft),C=parseFloat(b.marginTop);e.container.style.position="fixed",e.keepInViewport?(m>=e.minX&&m+i<h.width&&(e.lastPageX=n.pageX,e.container.style.left=m-S+"px"),g>=e.minY&&g+s<h.height&&(e.lastPageY=n.pageY,e.container.style.top=g-C+"px")):(e.lastPageX=n.pageX,e.container.style.left=m-S+"px",e.lastPageY=n.pageY,e.container.style.top=g-C+"px")}},window.document.addEventListener("mousemove",this.documentDragListener)},unbindDocumentDragListener:function(){this.documentDragListener&&(window.document.removeEventListener("mousemove",this.documentDragListener),this.documentDragListener=null)},bindDocumentDragEndListener:function(){var e=this;this.documentDragEndListener=function(n){e.dragging&&(e.dragging=!1,document.body.removeAttribute("data-p-unselectable-text"),!e.isUnstyled&&(document.body.style["user-select"]=""),e.$emit("dragend",n))},window.document.addEventListener("mouseup",this.documentDragEndListener)},unbindDocumentDragEndListener:function(){this.documentDragEndListener&&(window.document.removeEventListener("mouseup",this.documentDragEndListener),this.documentDragEndListener=null)}},computed:{maximizeIconComponent:function(){return this.maximized?this.minimizeIcon?"span":"WindowMinimizeIcon":this.maximizeIcon?"span":"WindowMaximizeIcon"},ariaLabelledById:function(){return this.header!=null||this.$attrs["aria-labelledby"]!==null?this.$id+"_header":null},closeAriaLabel:function(){return this.$primevue.config.locale.aria?this.$primevue.config.locale.aria.close:void 0},dataP:function(){return me({maximized:this.maximized,modal:this.modal})}},directives:{ripple:vt,focustrap:Vi},components:{Button:Un,Portal:yt,WindowMinimizeIcon:mn,WindowMaximizeIcon:fn,TimesIcon:et}};function De(t){"@babel/helpers - typeof";return De=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},De(t)}function Nt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function Ut(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Nt(Object(n),!0).forEach(function(i){Hi(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Nt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function Hi(t,e,n){return(e=Ni(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Ni(t){var e=Ui(t,"string");return De(e)=="symbol"?e:e+""}function Ui(t,e){if(De(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(De(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Wi=["data-p"],Gi=["aria-labelledby","aria-modal","data-p"],Zi=["id"],Yi=["data-p"];function Xi(t,e,n,i,s,o){var c=le("Button"),p=le("Portal"),m=ht("focustrap");return l(),G(p,{appendTo:t.appendTo},{default:ne(function(){return[s.containerVisible?(l(),d("div",w({key:0,ref:o.maskRef,class:t.cx("mask"),style:t.sx("mask",!0,{position:t.position,modal:t.modal}),onMousedown:e[1]||(e[1]=function(){return o.onMaskMouseDown&&o.onMaskMouseDown.apply(o,arguments)}),onMouseup:e[2]||(e[2]=function(){return o.onMaskMouseUp&&o.onMaskMouseUp.apply(o,arguments)}),"data-p":o.dataP},t.ptm("mask")),[K(gt,w({name:"p-dialog",onEnter:o.onEnter,onAfterEnter:o.onAfterEnter,onBeforeLeave:o.onBeforeLeave,onLeave:o.onLeave,onAfterLeave:o.onAfterLeave,appear:""},t.ptm("transition")),{default:ne(function(){return[t.visible?Se((l(),d("div",w({key:0,ref:o.containerRef,class:t.cx("root"),style:t.sx("root"),role:"dialog","aria-labelledby":o.ariaLabelledById,"aria-modal":t.modal,"data-p":o.dataP},t.ptmi("root")),[t.$slots.container?_(t.$slots,"container",{key:0,closeCallback:o.close,maximizeCallback:function(h){return o.maximize(h)},initDragCallback:o.initDrag}):(l(),d(J,{key:1},[t.showHeader?(l(),d("div",w({key:0,ref:o.headerContainerRef,class:t.cx("header"),onMousedown:e[0]||(e[0]=function(){return o.initDrag&&o.initDrag.apply(o,arguments)})},t.ptm("header")),[_(t.$slots,"header",{class:ee(t.cx("title"))},function(){return[t.header?(l(),d("span",w({key:0,id:o.ariaLabelledById,class:t.cx("title")},t.ptm("title")),v(t.header),17,Zi)):y("",!0)]}),f("div",w({class:t.cx("headerActions")},t.ptm("headerActions")),[t.maximizable?_(t.$slots,"maximizebutton",{key:0,maximized:s.maximized,maximizeCallback:function(h){return o.maximize(h)}},function(){return[K(c,w({ref:o.maximizableRef,autofocus:s.focusableMax,class:t.cx("pcMaximizeButton"),onClick:o.maximize,tabindex:t.maximizable?"0":"-1",unstyled:t.unstyled},t.maximizeButtonProps,{pt:t.ptm("pcMaximizeButton"),"data-pc-group-section":"headericon"}),{icon:ne(function(g){return[_(t.$slots,"maximizeicon",{maximized:s.maximized},function(){return[(l(),G(Ie(o.maximizeIconComponent),w({class:[g.class,s.maximized?t.minimizeIcon:t.maximizeIcon]},t.ptm("pcMaximizeButton").icon),null,16,["class"]))]})]}),_:3},16,["autofocus","class","onClick","tabindex","unstyled","pt"])]}):y("",!0),t.closable?_(t.$slots,"closebutton",{key:1,closeCallback:o.close},function(){return[K(c,w({ref:o.closeButtonRef,autofocus:s.focusableClose,class:t.cx("pcCloseButton"),onClick:o.close,"aria-label":o.closeAriaLabel,unstyled:t.unstyled},t.closeButtonProps,{pt:t.ptm("pcCloseButton"),"data-pc-group-section":"headericon"}),{icon:ne(function(g){return[_(t.$slots,"closeicon",{},function(){return[(l(),G(Ie(t.closeIcon?"span":"TimesIcon"),w({class:[t.closeIcon,g.class]},t.ptm("pcCloseButton").icon),null,16,["class"]))]})]}),_:3},16,["autofocus","class","onClick","aria-label","unstyled","pt"])]}):y("",!0)],16)],16)):y("",!0),f("div",w({ref:o.contentRef,class:[t.cx("content"),t.contentClass],style:t.contentStyle,"data-p":o.dataP},Ut(Ut({},t.contentProps),t.ptm("content"))),[_(t.$slots,"default")],16,Yi),t.footer||t.$slots.footer?(l(),d("div",w({key:1,ref:o.footerContainerRef,class:t.cx("footer")},t.ptm("footer")),[_(t.$slots,"footer",{},function(){return[F(v(t.footer),1)]})],16)):y("",!0)],64))],16,Gi)),[[m,{disabled:!t.modal}]]):y("",!0)]}),_:3},16,["onEnter","onAfterEnter","onBeforeLeave","onLeave","onAfterLeave"])],16,Wi)):y("",!0)]}),_:3},8,["appendTo"])}hn.render=Xi;function Ve(t){"@babel/helpers - typeof";return Ve=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Ve(t)}function Ji(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}function Qi(t,e){for(var n=0;n<e.length;n++){var i=e[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(t,eo(i.key),i)}}function qi(t,e,n){return e&&Qi(t.prototype,e),Object.defineProperty(t,"prototype",{writable:!1}),t}function eo(t){var e=to(t,"string");return Ve(e)=="symbol"?e:e+""}function to(t,e){if(Ve(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Ve(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return String(t)}var no=(function(){function t(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:function(){};Ji(this,t),this.element=e,this.listener=n}return qi(t,[{key:"bindScrollListener",value:function(){this.scrollableParents=Xn(this.element);for(var n=0;n<this.scrollableParents.length;n++)this.scrollableParents[n].addEventListener("scroll",this.listener)}},{key:"unbindScrollListener",value:function(){if(this.scrollableParents)for(var n=0;n<this.scrollableParents.length;n++)this.scrollableParents[n].removeEventListener("scroll",this.listener)}},{key:"destroy",value:function(){this.unbindScrollListener(),this.element=null,this.listener=null,this.scrollableParents=null}}])})(),gn={name:"ChevronDownIcon",extends:He};function io(t){return ro(t)||ao(t)||so(t)||oo()}function oo(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function so(t,e){if(t){if(typeof t=="string")return pt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?pt(t,e):void 0}}function ao(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function ro(t){if(Array.isArray(t))return pt(t)}function pt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function lo(t,e,n,i,s,o){return l(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),io(e[0]||(e[0]=[f("path",{d:"M7.01744 10.398C6.91269 10.3985 6.8089 10.378 6.71215 10.3379C6.61541 10.2977 6.52766 10.2386 6.45405 10.1641L1.13907 4.84913C1.03306 4.69404 0.985221 4.5065 1.00399 4.31958C1.02276 4.13266 1.10693 3.95838 1.24166 3.82747C1.37639 3.69655 1.55301 3.61742 1.74039 3.60402C1.92777 3.59062 2.11386 3.64382 2.26584 3.75424L7.01744 8.47394L11.769 3.75424C11.9189 3.65709 12.097 3.61306 12.2748 3.62921C12.4527 3.64535 12.6199 3.72073 12.7498 3.84328C12.8797 3.96582 12.9647 4.12842 12.9912 4.30502C13.0177 4.48162 12.9841 4.662 12.8958 4.81724L7.58083 10.1322C7.50996 10.2125 7.42344 10.2775 7.32656 10.3232C7.22968 10.3689 7.12449 10.3944 7.01744 10.398Z",fill:"currentColor"},null,-1)])),16)}gn.render=lo;var vn={name:"TimesCircleIcon",extends:He};function uo(t){return mo(t)||fo(t)||po(t)||co()}function co(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function po(t,e){if(t){if(typeof t=="string")return ft(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?ft(t,e):void 0}}function fo(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function mo(t){if(Array.isArray(t))return ft(t)}function ft(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}function ho(t,e,n,i,s,o){return l(),d("svg",w({width:"14",height:"14",viewBox:"0 0 14 14",fill:"none",xmlns:"http://www.w3.org/2000/svg"},t.pti()),uo(e[0]||(e[0]=[f("path",{"fill-rule":"evenodd","clip-rule":"evenodd",d:"M7 14C5.61553 14 4.26215 13.5895 3.11101 12.8203C1.95987 12.0511 1.06266 10.9579 0.532846 9.67879C0.00303296 8.3997 -0.13559 6.99224 0.134506 5.63437C0.404603 4.2765 1.07129 3.02922 2.05026 2.05026C3.02922 1.07129 4.2765 0.404603 5.63437 0.134506C6.99224 -0.13559 8.3997 0.00303296 9.67879 0.532846C10.9579 1.06266 12.0511 1.95987 12.8203 3.11101C13.5895 4.26215 14 5.61553 14 7C14 8.85652 13.2625 10.637 11.9497 11.9497C10.637 13.2625 8.85652 14 7 14ZM7 1.16667C5.84628 1.16667 4.71846 1.50879 3.75918 2.14976C2.79989 2.79074 2.05222 3.70178 1.61071 4.76768C1.16919 5.83358 1.05367 7.00647 1.27876 8.13803C1.50384 9.26958 2.05941 10.309 2.87521 11.1248C3.69102 11.9406 4.73042 12.4962 5.86198 12.7212C6.99353 12.9463 8.16642 12.8308 9.23232 12.3893C10.2982 11.9478 11.2093 11.2001 11.8502 10.2408C12.4912 9.28154 12.8333 8.15373 12.8333 7C12.8333 5.45291 12.2188 3.96918 11.1248 2.87521C10.0308 1.78125 8.5471 1.16667 7 1.16667ZM4.66662 9.91668C4.58998 9.91704 4.51404 9.90209 4.44325 9.87271C4.37246 9.84333 4.30826 9.8001 4.2544 9.74557C4.14516 9.6362 4.0838 9.48793 4.0838 9.33335C4.0838 9.17876 4.14516 9.0305 4.2544 8.92113L6.17553 7L4.25443 5.07891C4.15139 4.96832 4.09529 4.82207 4.09796 4.67094C4.10063 4.51982 4.16185 4.37563 4.26872 4.26876C4.3756 4.16188 4.51979 4.10066 4.67091 4.09799C4.82204 4.09532 4.96829 4.15142 5.07887 4.25446L6.99997 6.17556L8.92106 4.25446C9.03164 4.15142 9.1779 4.09532 9.32903 4.09799C9.48015 4.10066 9.62434 4.16188 9.73121 4.26876C9.83809 4.37563 9.89931 4.51982 9.90198 4.67094C9.90464 4.82207 9.84855 4.96832 9.74551 5.07891L7.82441 7L9.74554 8.92113C9.85478 9.0305 9.91614 9.17876 9.91614 9.33335C9.91614 9.48793 9.85478 9.6362 9.74554 9.74557C9.69168 9.8001 9.62748 9.84333 9.55669 9.87271C9.4859 9.90209 9.40996 9.91704 9.33332 9.91668C9.25668 9.91704 9.18073 9.90209 9.10995 9.87271C9.03916 9.84333 8.97495 9.8001 8.9211 9.74557L6.99997 7.82444L5.07884 9.74557C5.02499 9.8001 4.96078 9.84333 4.88999 9.87271C4.81921 9.90209 4.74326 9.91704 4.66662 9.91668Z",fill:"currentColor"},null,-1)])),16)}vn.render=ho;var go=`
    .p-chip {
        display: inline-flex;
        align-items: center;
        background: dt('chip.background');
        color: dt('chip.color');
        border-radius: dt('chip.border.radius');
        padding-block: dt('chip.padding.y');
        padding-inline: dt('chip.padding.x');
        gap: dt('chip.gap');
    }

    .p-chip-icon {
        color: dt('chip.icon.color');
        font-size: dt('chip.icon.size');
        width: dt('chip.icon.size');
        height: dt('chip.icon.size');
    }

    .p-chip-image {
        border-radius: 50%;
        width: dt('chip.image.width');
        height: dt('chip.image.height');
        margin-inline-start: calc(-1 * dt('chip.padding.y'));
    }

    .p-chip:has(.p-chip-remove-icon) {
        padding-inline-end: dt('chip.padding.y');
    }

    .p-chip:has(.p-chip-image) {
        padding-block-start: calc(dt('chip.padding.y') / 2);
        padding-block-end: calc(dt('chip.padding.y') / 2);
    }

    .p-chip-remove-icon {
        cursor: pointer;
        font-size: dt('chip.remove.icon.size');
        width: dt('chip.remove.icon.size');
        height: dt('chip.remove.icon.size');
        color: dt('chip.remove.icon.color');
        border-radius: 50%;
        transition:
            outline-color dt('chip.transition.duration'),
            box-shadow dt('chip.transition.duration');
        outline-color: transparent;
    }

    .p-chip-remove-icon:focus-visible {
        box-shadow: dt('chip.remove.icon.focus.ring.shadow');
        outline: dt('chip.remove.icon.focus.ring.width') dt('chip.remove.icon.focus.ring.style') dt('chip.remove.icon.focus.ring.color');
        outline-offset: dt('chip.remove.icon.focus.ring.offset');
    }
`,vo={root:"p-chip p-component",image:"p-chip-image",icon:"p-chip-icon",label:"p-chip-label",removeIcon:"p-chip-remove-icon"},yo=he.extend({name:"chip",style:go,classes:vo}),bo={name:"BaseChip",extends:Ne,props:{label:{type:[String,Number],default:null},icon:{type:String,default:null},image:{type:String,default:null},removable:{type:Boolean,default:!1},removeIcon:{type:String,default:void 0}},style:yo,provide:function(){return{$pcChip:this,$parentInstance:this}}},yn={name:"Chip",extends:bo,inheritAttrs:!1,emits:["remove"],data:function(){return{visible:!0}},methods:{onKeydown:function(e){(e.key==="Enter"||e.key==="Backspace")&&this.close(e)},close:function(e){this.visible=!1,this.$emit("remove",e)}},computed:{dataP:function(){return me({removable:this.removable})}},components:{TimesCircleIcon:vn}},wo=["aria-label","data-p"],Co=["src"];function So(t,e,n,i,s,o){return s.visible?(l(),d("div",w({key:0,class:t.cx("root"),"aria-label":t.label},t.ptmi("root"),{"data-p":o.dataP}),[_(t.$slots,"default",{},function(){return[t.image?(l(),d("img",w({key:0,src:t.image},t.ptm("image"),{class:t.cx("image")}),null,16,Co)):t.$slots.icon?(l(),G(Ie(t.$slots.icon),w({key:1,class:t.cx("icon")},t.ptm("icon")),null,16,["class"])):t.icon?(l(),d("span",w({key:2,class:[t.cx("icon"),t.icon]},t.ptm("icon")),null,16)):y("",!0),t.label!==null?(l(),d("div",w({key:3,class:t.cx("label")},t.ptm("label")),v(t.label),17)):y("",!0)]}),t.removable?_(t.$slots,"removeicon",{key:0,removeCallback:o.close,keydownCallback:o.onKeydown},function(){return[(l(),G(Ie(t.removeIcon?"span":"TimesCircleIcon"),w({class:[t.cx("removeIcon"),t.removeIcon],onClick:o.close,onKeydown:o.onKeydown},t.ptm("removeIcon")),null,16,["class","onClick","onKeydown"]))]}):y("",!0)],16,wo)):y("",!0)}yn.render=So;var ko={name:"BaseEditableHolder",extends:Ne,emits:["update:modelValue","value-change"],props:{modelValue:{type:null,default:void 0},defaultValue:{type:null,default:void 0},name:{type:String,default:void 0},invalid:{type:Boolean,default:void 0},disabled:{type:Boolean,default:!1},formControl:{type:Object,default:void 0}},inject:{$parentInstance:{default:void 0},$pcForm:{default:void 0},$pcFormField:{default:void 0}},data:function(){return{d_value:this.defaultValue!==void 0?this.defaultValue:this.modelValue}},watch:{modelValue:{deep:!0,handler:function(e){this.d_value=e}},defaultValue:function(e){this.d_value=e},$formName:{immediate:!0,handler:function(e){var n,i;this.formField=((n=this.$pcForm)===null||n===void 0||(i=n.register)===null||i===void 0?void 0:i.call(n,e,this.$formControl))||{}}},$formControl:{immediate:!0,handler:function(e){var n,i;this.formField=((n=this.$pcForm)===null||n===void 0||(i=n.register)===null||i===void 0?void 0:i.call(n,this.$formName,e))||{}}},$formDefaultValue:{immediate:!0,handler:function(e){this.d_value!==e&&(this.d_value=e)}},$formValue:{immediate:!1,handler:function(e){var n;(n=this.$pcForm)!==null&&n!==void 0&&n.getFieldState(this.$formName)&&e!==this.d_value&&(this.d_value=e)}}},formField:{},methods:{writeValue:function(e,n){var i,s;this.controlled&&(this.d_value=e,this.$emit("update:modelValue",e)),this.$emit("value-change",e),(i=(s=this.formField).onChange)===null||i===void 0||i.call(s,{originalEvent:n,value:e})},findNonEmpty:function(){for(var e=arguments.length,n=new Array(e),i=0;i<e;i++)n[i]=arguments[i];return n.find(fe)}},computed:{$filled:function(){return fe(this.d_value)},$invalid:function(){var e,n;return!this.$formNovalidate&&this.findNonEmpty(this.invalid,(e=this.$pcFormField)===null||e===void 0||(e=e.$field)===null||e===void 0?void 0:e.invalid,(n=this.$pcForm)===null||n===void 0||(n=n.getFieldState(this.$formName))===null||n===void 0?void 0:n.invalid)},$formName:function(){var e;return this.$formNovalidate?void 0:this.name||((e=this.$formControl)===null||e===void 0?void 0:e.name)},$formControl:function(){var e;return this.formControl||((e=this.$pcFormField)===null||e===void 0?void 0:e.formControl)},$formNovalidate:function(){var e;return(e=this.$formControl)===null||e===void 0?void 0:e.novalidate},$formDefaultValue:function(){var e,n;return this.findNonEmpty(this.d_value,(e=this.$pcFormField)===null||e===void 0?void 0:e.initialValue,(n=this.$pcForm)===null||n===void 0||(n=n.initialValues)===null||n===void 0?void 0:n[this.$formName])},$formValue:function(){var e,n;return this.findNonEmpty((e=this.$pcFormField)===null||e===void 0||(e=e.$field)===null||e===void 0?void 0:e.value,(n=this.$pcForm)===null||n===void 0||(n=n.getFieldState(this.$formName))===null||n===void 0?void 0:n.value)},controlled:function(){return this.$inProps.hasOwnProperty("modelValue")||!this.$inProps.hasOwnProperty("modelValue")&&!this.$inProps.hasOwnProperty("defaultValue")},filled:function(){return this.$filled}}},bn={name:"BaseInput",extends:ko,props:{size:{type:String,default:null},fluid:{type:Boolean,default:null},variant:{type:String,default:null}},inject:{$parentInstance:{default:void 0},$pcFluid:{default:void 0}},computed:{$variant:function(){var e;return(e=this.variant)!==null&&e!==void 0?e:this.$primevue.config.inputStyle||this.$primevue.config.inputVariant},$fluid:function(){var e;return(e=this.fluid)!==null&&e!==void 0?e:!!this.$pcFluid},hasFluid:function(){return this.$fluid}}},Io=`
    .p-inputtext {
        font-family: inherit;
        font-feature-settings: inherit;
        font-size: 1rem;
        color: dt('inputtext.color');
        background: dt('inputtext.background');
        padding-block: dt('inputtext.padding.y');
        padding-inline: dt('inputtext.padding.x');
        border: 1px solid dt('inputtext.border.color');
        transition:
            background dt('inputtext.transition.duration'),
            color dt('inputtext.transition.duration'),
            border-color dt('inputtext.transition.duration'),
            outline-color dt('inputtext.transition.duration'),
            box-shadow dt('inputtext.transition.duration');
        appearance: none;
        border-radius: dt('inputtext.border.radius');
        outline-color: transparent;
        box-shadow: dt('inputtext.shadow');
    }

    .p-inputtext:enabled:hover {
        border-color: dt('inputtext.hover.border.color');
    }

    .p-inputtext:enabled:focus {
        border-color: dt('inputtext.focus.border.color');
        box-shadow: dt('inputtext.focus.ring.shadow');
        outline: dt('inputtext.focus.ring.width') dt('inputtext.focus.ring.style') dt('inputtext.focus.ring.color');
        outline-offset: dt('inputtext.focus.ring.offset');
    }

    .p-inputtext.p-invalid {
        border-color: dt('inputtext.invalid.border.color');
    }

    .p-inputtext.p-variant-filled {
        background: dt('inputtext.filled.background');
    }

    .p-inputtext.p-variant-filled:enabled:hover {
        background: dt('inputtext.filled.hover.background');
    }

    .p-inputtext.p-variant-filled:enabled:focus {
        background: dt('inputtext.filled.focus.background');
    }

    .p-inputtext:disabled {
        opacity: 1;
        background: dt('inputtext.disabled.background');
        color: dt('inputtext.disabled.color');
    }

    .p-inputtext::placeholder {
        color: dt('inputtext.placeholder.color');
    }

    .p-inputtext.p-invalid::placeholder {
        color: dt('inputtext.invalid.placeholder.color');
    }

    .p-inputtext-sm {
        font-size: dt('inputtext.sm.font.size');
        padding-block: dt('inputtext.sm.padding.y');
        padding-inline: dt('inputtext.sm.padding.x');
    }

    .p-inputtext-lg {
        font-size: dt('inputtext.lg.font.size');
        padding-block: dt('inputtext.lg.padding.y');
        padding-inline: dt('inputtext.lg.padding.x');
    }

    .p-inputtext-fluid {
        width: 100%;
    }
`,Oo={root:function(e){var n=e.instance,i=e.props;return["p-inputtext p-component",{"p-filled":n.$filled,"p-inputtext-sm p-inputfield-sm":i.size==="small","p-inputtext-lg p-inputfield-lg":i.size==="large","p-invalid":n.$invalid,"p-variant-filled":n.$variant==="filled","p-inputtext-fluid":n.$fluid}]}},xo=he.extend({name:"inputtext",style:Io,classes:Oo}),$o={name:"BaseInputText",extends:bn,style:xo,provide:function(){return{$pcInputText:this,$parentInstance:this}}};function Te(t){"@babel/helpers - typeof";return Te=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Te(t)}function zo(t,e,n){return(e=Lo(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Lo(t){var e=_o(t,"string");return Te(e)=="symbol"?e:e+""}function _o(t,e){if(Te(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Te(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var bt={name:"InputText",extends:$o,inheritAttrs:!1,methods:{onInput:function(e){this.writeValue(e.target.value,e)}},computed:{attrs:function(){return w(this.ptmi("root",{context:{filled:this.$filled,disabled:this.disabled}}),this.formField)},dataP:function(){return me(zo({invalid:this.$invalid,fluid:this.$fluid,filled:this.$variant==="filled"},this.size,this.size))}}},Po=["value","name","disabled","aria-invalid","data-p"];function Eo(t,e,n,i,s,o){return l(),d("input",w({type:"text",class:t.cx("root"),value:t.d_value,name:t.name,disabled:t.disabled,"aria-invalid":t.$invalid||void 0,"data-p":o.dataP,onInput:e[0]||(e[0]=function(){return o.onInput&&o.onInput.apply(o,arguments)})},o.attrs),null,16,Po)}bt.render=Eo;var Mo=Jn(),Ao=`
    .p-virtualscroller-loader {
        background: dt('virtualscroller.loader.mask.background');
        color: dt('virtualscroller.loader.mask.color');
    }

    .p-virtualscroller-loading-icon {
        font-size: dt('virtualscroller.loader.icon.size');
        width: dt('virtualscroller.loader.icon.size');
        height: dt('virtualscroller.loader.icon.size');
    }
`,Do=`
.p-virtualscroller {
    position: relative;
    overflow: auto;
    contain: strict;
    transform: translateZ(0);
    will-change: scroll-position;
    outline: 0 none;
}

.p-virtualscroller-content {
    position: absolute;
    top: 0;
    left: 0;
    min-height: 100%;
    min-width: 100%;
    will-change: transform;
}

.p-virtualscroller-spacer {
    position: absolute;
    top: 0;
    left: 0;
    height: 1px;
    width: 1px;
    transform-origin: 0 0;
    pointer-events: none;
}

.p-virtualscroller-loader {
    position: sticky;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
}

.p-virtualscroller-loader-mask {
    display: flex;
    align-items: center;
    justify-content: center;
}

.p-virtualscroller-horizontal > .p-virtualscroller-content {
    display: flex;
}

.p-virtualscroller-inline .p-virtualscroller-content {
    position: static;
}

.p-virtualscroller .p-virtualscroller-loading {
    transform: none !important;
    min-height: 0;
    position: sticky;
    inset-block-start: 0;
    inset-inline-start: 0;
}
`,Wt=he.extend({name:"virtualscroller",css:Do,style:Ao}),Vo={name:"BaseVirtualScroller",extends:Ne,props:{id:{type:String,default:null},style:null,class:null,items:{type:Array,default:null},itemSize:{type:[Number,Array],default:0},scrollHeight:null,scrollWidth:null,orientation:{type:String,default:"vertical"},numToleratedItems:{type:Number,default:null},delay:{type:Number,default:0},resizeDelay:{type:Number,default:10},lazy:{type:Boolean,default:!1},disabled:{type:Boolean,default:!1},loaderDisabled:{type:Boolean,default:!1},columns:{type:Array,default:null},loading:{type:Boolean,default:!1},showSpacer:{type:Boolean,default:!0},showLoader:{type:Boolean,default:!1},tabindex:{type:Number,default:0},inline:{type:Boolean,default:!1},step:{type:Number,default:0},appendOnly:{type:Boolean,default:!1},autoSize:{type:Boolean,default:!1}},style:Wt,provide:function(){return{$pcVirtualScroller:this,$parentInstance:this}},beforeMount:function(){var e;Wt.loadCSS({nonce:(e=this.$primevueConfig)===null||e===void 0||(e=e.csp)===null||e===void 0?void 0:e.nonce})}};function Be(t){"@babel/helpers - typeof";return Be=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Be(t)}function Gt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function Me(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Gt(Object(n),!0).forEach(function(i){wn(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Gt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function wn(t,e,n){return(e=To(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function To(t){var e=Bo(t,"string");return Be(e)=="symbol"?e:e+""}function Bo(t,e){if(Be(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Be(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Cn={name:"VirtualScroller",extends:Vo,inheritAttrs:!1,emits:["update:numToleratedItems","scroll","scroll-index-change","lazy-load"],data:function(){var e=this.isBoth();return{first:e?{rows:0,cols:0}:0,last:e?{rows:0,cols:0}:0,page:e?{rows:0,cols:0}:0,numItemsInViewport:e?{rows:0,cols:0}:0,lastScrollPos:e?{top:0,left:0}:0,d_numToleratedItems:this.numToleratedItems,d_loading:this.loading,loaderArr:[],spacerStyle:{},contentStyle:{}}},element:null,content:null,lastScrollPos:null,scrollTimeout:null,resizeTimeout:null,defaultWidth:0,defaultHeight:0,defaultContentWidth:0,defaultContentHeight:0,isRangeChanged:!1,lazyLoadState:{},resizeListener:null,resizeObserver:null,initialized:!1,watch:{numToleratedItems:function(e){this.d_numToleratedItems=e},loading:function(e,n){this.lazy&&e!==n&&e!==this.d_loading&&(this.d_loading=e)},items:{handler:function(e,n){(!n||n.length!==(e||[]).length)&&(this.init(),this.calculateAutoSize())},deep:!0},itemSize:function(){this.init(),this.calculateAutoSize()},orientation:function(){this.lastScrollPos=this.isBoth()?{top:0,left:0}:0},scrollHeight:function(){this.init(),this.calculateAutoSize()},scrollWidth:function(){this.init(),this.calculateAutoSize()}},mounted:function(){this.viewInit(),this.lastScrollPos=this.isBoth()?{top:0,left:0}:0,this.lazyLoadState=this.lazyLoadState||{}},updated:function(){!this.initialized&&this.viewInit()},unmounted:function(){this.unbindResizeListener(),this.initialized=!1},methods:{viewInit:function(){Ft(this.element)&&(this.setContentEl(this.content),this.init(),this.calculateAutoSize(),this.defaultWidth=Le(this.element),this.defaultHeight=_e(this.element),this.defaultContentWidth=Le(this.content),this.defaultContentHeight=_e(this.content),this.initialized=!0),this.element&&this.bindResizeListener()},init:function(){this.disabled||(this.setSize(),this.calculateOptions(),this.setSpacerSize())},isVertical:function(){return this.orientation==="vertical"},isHorizontal:function(){return this.orientation==="horizontal"},isBoth:function(){return this.orientation==="both"},scrollTo:function(e){this.element&&this.element.scrollTo(e)},scrollToIndex:function(e){var n=this,i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"auto",s=this.isBoth(),o=this.isHorizontal(),c=s?e.every(function(k){return k>-1}):e>-1;if(c){var p=this.first,m=this.element,g=m.scrollTop,h=g===void 0?0:g,b=m.scrollLeft,S=b===void 0?0:b,C=this.calculateNumItems(),O=C.numToleratedItems,L=this.getContentPosition(),P=this.itemSize,M=function(){var D=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,H=arguments.length>1?arguments[1]:void 0;return D<=H?0:D},A=function(D,H,Q){return D*H+Q},j=function(){var D=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,H=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;return n.scrollTo({left:D,top:H,behavior:i})},x=s?{rows:0,cols:0}:0,R=!1,z=!1;s?(x={rows:M(e[0],O[0]),cols:M(e[1],O[1])},j(A(x.cols,P[1],L.left),A(x.rows,P[0],L.top)),z=this.lastScrollPos.top!==h||this.lastScrollPos.left!==S,R=x.rows!==p.rows||x.cols!==p.cols):(x=M(e,O),o?j(A(x,P,L.left),h):j(S,A(x,P,L.top)),z=this.lastScrollPos!==(o?S:h),R=x!==p),this.isRangeChanged=R,z&&(this.first=x)}},scrollInView:function(e,n){var i=this,s=arguments.length>2&&arguments[2]!==void 0?arguments[2]:"auto";if(n){var o=this.isBoth(),c=this.isHorizontal(),p=o?e.every(function(P){return P>-1}):e>-1;if(p){var m=this.getRenderedRange(),g=m.first,h=m.viewport,b=function(){var M=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,A=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;return i.scrollTo({left:M,top:A,behavior:s})},S=n==="to-start",C=n==="to-end";if(S){if(o)h.first.rows-g.rows>e[0]?b(h.first.cols*this.itemSize[1],(h.first.rows-1)*this.itemSize[0]):h.first.cols-g.cols>e[1]&&b((h.first.cols-1)*this.itemSize[1],h.first.rows*this.itemSize[0]);else if(h.first-g>e){var O=(h.first-1)*this.itemSize;c?b(O,0):b(0,O)}}else if(C){if(o)h.last.rows-g.rows<=e[0]+1?b(h.first.cols*this.itemSize[1],(h.first.rows+1)*this.itemSize[0]):h.last.cols-g.cols<=e[1]+1&&b((h.first.cols+1)*this.itemSize[1],h.first.rows*this.itemSize[0]);else if(h.last-g<=e+1){var L=(h.first+1)*this.itemSize;c?b(L,0):b(0,L)}}}}else this.scrollToIndex(e,s)},getRenderedRange:function(){var e=function(b,S){return Math.floor(b/(S||b))},n=this.first,i=0;if(this.element){var s=this.isBoth(),o=this.isHorizontal(),c=this.element,p=c.scrollTop,m=c.scrollLeft;if(s)n={rows:e(p,this.itemSize[0]),cols:e(m,this.itemSize[1])},i={rows:n.rows+this.numItemsInViewport.rows,cols:n.cols+this.numItemsInViewport.cols};else{var g=o?m:p;n=e(g,this.itemSize),i=n+this.numItemsInViewport}}return{first:this.first,last:this.last,viewport:{first:n,last:i}}},calculateNumItems:function(){var e=this.isBoth(),n=this.isHorizontal(),i=this.itemSize,s=this.getContentPosition(),o=this.element?this.element.offsetWidth-s.left:0,c=this.element?this.element.offsetHeight-s.top:0,p=function(S,C){return Math.ceil(S/(C||S))},m=function(S){return Math.ceil(S/2)},g=e?{rows:p(c,i[0]),cols:p(o,i[1])}:p(n?o:c,i),h=this.d_numToleratedItems||(e?[m(g.rows),m(g.cols)]:m(g));return{numItemsInViewport:g,numToleratedItems:h}},calculateOptions:function(){var e=this,n=this.isBoth(),i=this.first,s=this.calculateNumItems(),o=s.numItemsInViewport,c=s.numToleratedItems,p=function(h,b,S){var C=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!1;return e.getLast(h+b+(h<S?2:3)*S,C)},m=n?{rows:p(i.rows,o.rows,c[0]),cols:p(i.cols,o.cols,c[1],!0)}:p(i,o,c);this.last=m,this.numItemsInViewport=o,this.d_numToleratedItems=c,this.$emit("update:numToleratedItems",this.d_numToleratedItems),this.showLoader&&(this.loaderArr=n?Array.from({length:o.rows}).map(function(){return Array.from({length:o.cols})}):Array.from({length:o})),this.lazy&&Promise.resolve().then(function(){var g;e.lazyLoadState={first:e.step?n?{rows:0,cols:i.cols}:0:i,last:Math.min(e.step?e.step:m,((g=e.items)===null||g===void 0?void 0:g.length)||0)},e.$emit("lazy-load",e.lazyLoadState)})},calculateAutoSize:function(){var e=this;this.autoSize&&!this.d_loading&&Promise.resolve().then(function(){if(e.content){var n=e.isBoth(),i=e.isHorizontal(),s=e.isVertical();e.content.style.minHeight=e.content.style.minWidth="auto",e.content.style.position="relative",e.element.style.contain="none";var o=[Le(e.element),_e(e.element)],c=o[0],p=o[1];(n||i)&&(e.element.style.width=c<e.defaultWidth?c+"px":e.scrollWidth||e.defaultWidth+"px"),(n||s)&&(e.element.style.height=p<e.defaultHeight?p+"px":e.scrollHeight||e.defaultHeight+"px"),e.content.style.minHeight=e.content.style.minWidth="",e.content.style.position="",e.element.style.contain=""}})},getLast:function(){var e,n,i=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,s=arguments.length>1?arguments[1]:void 0;return this.items?Math.min(s?((e=this.columns||this.items[0])===null||e===void 0?void 0:e.length)||0:((n=this.items)===null||n===void 0?void 0:n.length)||0,i):0},getContentPosition:function(){if(this.content){var e=getComputedStyle(this.content),n=parseFloat(e.paddingLeft)+Math.max(parseFloat(e.left)||0,0),i=parseFloat(e.paddingRight)+Math.max(parseFloat(e.right)||0,0),s=parseFloat(e.paddingTop)+Math.max(parseFloat(e.top)||0,0),o=parseFloat(e.paddingBottom)+Math.max(parseFloat(e.bottom)||0,0);return{left:n,right:i,top:s,bottom:o,x:n+i,y:s+o}}return{left:0,right:0,top:0,bottom:0,x:0,y:0}},setSize:function(){var e=this;if(this.element){var n=this.isBoth(),i=this.isHorizontal(),s=this.element.parentElement,o=this.scrollWidth||"".concat(this.element.offsetWidth||s.offsetWidth,"px"),c=this.scrollHeight||"".concat(this.element.offsetHeight||s.offsetHeight,"px"),p=function(g,h){return e.element.style[g]=h};n||i?(p("height",c),p("width",o)):p("height",c)}},setSpacerSize:function(){var e=this,n=this.items;if(n){var i=this.isBoth(),s=this.isHorizontal(),o=this.getContentPosition(),c=function(m,g,h){var b=arguments.length>3&&arguments[3]!==void 0?arguments[3]:0;return e.spacerStyle=Me(Me({},e.spacerStyle),wn({},"".concat(m),(g||[]).length*h+b+"px"))};i?(c("height",n,this.itemSize[0],o.y),c("width",this.columns||n[1],this.itemSize[1],o.x)):s?c("width",this.columns||n,this.itemSize,o.x):c("height",n,this.itemSize,o.y)}},setContentPosition:function(e){var n=this;if(this.content&&!this.appendOnly){var i=this.isBoth(),s=this.isHorizontal(),o=e?e.first:this.first,c=function(h,b){return h*b},p=function(){var h=arguments.length>0&&arguments[0]!==void 0?arguments[0]:0,b=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;return n.contentStyle=Me(Me({},n.contentStyle),{transform:"translate3d(".concat(h,"px, ").concat(b,"px, 0)")})};if(i)p(c(o.cols,this.itemSize[1]),c(o.rows,this.itemSize[0]));else{var m=c(o,this.itemSize);s?p(m,0):p(0,m)}}},onScrollPositionChange:function(e){var n=this,i=e.target,s=this.isBoth(),o=this.isHorizontal(),c=this.getContentPosition(),p=function($,Z){return $?$>Z?$-Z:$:0},m=function($,Z){return Math.floor($/(Z||$))},g=function($,Z,oe,q,U,se){return $<=U?U:se?oe-q-U:Z+U-1},h=function($,Z,oe,q,U,se,ge,xe){if($<=se)return 0;var V=Math.max(0,ge?$<Z?oe:$-se:$>Z?oe:$-2*se),$e=n.getLast(V,xe);return V>$e?$e-U:V},b=function($,Z,oe,q,U,se){var ge=Z+q+2*U;return $>=U&&(ge+=U+1),n.getLast(ge,se)},S=p(i.scrollTop,c.top),C=p(i.scrollLeft,c.left),O=s?{rows:0,cols:0}:0,L=this.last,P=!1,M=this.lastScrollPos;if(s){var A=this.lastScrollPos.top<=S,j=this.lastScrollPos.left<=C;if(!this.appendOnly||this.appendOnly&&(A||j)){var x={rows:m(S,this.itemSize[0]),cols:m(C,this.itemSize[1])},R={rows:g(x.rows,this.first.rows,this.last.rows,this.numItemsInViewport.rows,this.d_numToleratedItems[0],A),cols:g(x.cols,this.first.cols,this.last.cols,this.numItemsInViewport.cols,this.d_numToleratedItems[1],j)};O={rows:h(x.rows,R.rows,this.first.rows,this.last.rows,this.numItemsInViewport.rows,this.d_numToleratedItems[0],A),cols:h(x.cols,R.cols,this.first.cols,this.last.cols,this.numItemsInViewport.cols,this.d_numToleratedItems[1],j,!0)},L={rows:b(x.rows,O.rows,this.last.rows,this.numItemsInViewport.rows,this.d_numToleratedItems[0]),cols:b(x.cols,O.cols,this.last.cols,this.numItemsInViewport.cols,this.d_numToleratedItems[1],!0)},P=O.rows!==this.first.rows||L.rows!==this.last.rows||O.cols!==this.first.cols||L.cols!==this.last.cols||this.isRangeChanged,M={top:S,left:C}}}else{var z=o?C:S,k=this.lastScrollPos<=z;if(!this.appendOnly||this.appendOnly&&k){var D=m(z,this.itemSize),H=g(D,this.first,this.last,this.numItemsInViewport,this.d_numToleratedItems,k);O=h(D,H,this.first,this.last,this.numItemsInViewport,this.d_numToleratedItems,k),L=b(D,O,this.last,this.numItemsInViewport,this.d_numToleratedItems),P=O!==this.first||L!==this.last||this.isRangeChanged,M=z}}return{first:O,last:L,isRangeChanged:P,scrollPos:M}},onScrollChange:function(e){var n=this.onScrollPositionChange(e),i=n.first,s=n.last,o=n.isRangeChanged,c=n.scrollPos;if(o){var p={first:i,last:s};if(this.setContentPosition(p),this.first=i,this.last=s,this.lastScrollPos=c,this.$emit("scroll-index-change",p),this.lazy&&this.isPageChanged(i)){var m,g,h={first:this.step?Math.min(this.getPageByFirst(i)*this.step,(((m=this.items)===null||m===void 0?void 0:m.length)||0)-this.step):i,last:Math.min(this.step?(this.getPageByFirst(i)+1)*this.step:s,((g=this.items)===null||g===void 0?void 0:g.length)||0)},b=this.lazyLoadState.first!==h.first||this.lazyLoadState.last!==h.last;b&&this.$emit("lazy-load",h),this.lazyLoadState=h}}},onScroll:function(e){var n=this;if(this.$emit("scroll",e),this.delay){if(this.scrollTimeout&&clearTimeout(this.scrollTimeout),this.isPageChanged()){if(!this.d_loading&&this.showLoader){var i=this.onScrollPositionChange(e),s=i.isRangeChanged,o=s||(this.step?this.isPageChanged():!1);o&&(this.d_loading=!0)}this.scrollTimeout=setTimeout(function(){n.onScrollChange(e),n.d_loading&&n.showLoader&&(!n.lazy||n.loading===void 0)&&(n.d_loading=!1,n.page=n.getPageByFirst())},this.delay)}}else this.onScrollChange(e)},onResize:function(){var e=this;this.resizeTimeout&&clearTimeout(this.resizeTimeout),this.resizeTimeout=setTimeout(function(){if(Ft(e.element)){var n=e.isBoth(),i=e.isVertical(),s=e.isHorizontal(),o=[Le(e.element),_e(e.element)],c=o[0],p=o[1],m=c!==e.defaultWidth,g=p!==e.defaultHeight,h=n?m||g:s?m:i?g:!1;h&&(e.d_numToleratedItems=e.numToleratedItems,e.defaultWidth=c,e.defaultHeight=p,e.defaultContentWidth=Le(e.content),e.defaultContentHeight=_e(e.content),e.init())}},this.resizeDelay)},bindResizeListener:function(){var e=this;this.resizeListener||(this.resizeListener=this.onResize.bind(this),window.addEventListener("resize",this.resizeListener),window.addEventListener("orientationchange",this.resizeListener),this.resizeObserver=new ResizeObserver(function(){e.onResize()}),this.resizeObserver.observe(this.element))},unbindResizeListener:function(){this.resizeListener&&(window.removeEventListener("resize",this.resizeListener),window.removeEventListener("orientationchange",this.resizeListener),this.resizeListener=null),this.resizeObserver&&(this.resizeObserver.disconnect(),this.resizeObserver=null)},getOptions:function(e){var n=(this.items||[]).length,i=this.isBoth()?this.first.rows+e:this.first+e;return{index:i,count:n,first:i===0,last:i===n-1,even:i%2===0,odd:i%2!==0}},getLoaderOptions:function(e,n){var i=this.loaderArr.length;return Me({index:e,count:i,first:e===0,last:e===i-1,even:e%2===0,odd:e%2!==0},n)},getPageByFirst:function(e){return Math.floor(((e??this.first)+this.d_numToleratedItems*4)/(this.step||1))},isPageChanged:function(e){return this.step&&!this.lazy?this.page!==this.getPageByFirst(e??this.first):!0},setContentEl:function(e){this.content=e||this.content||un(this.element,'[data-pc-section="content"]')},elementRef:function(e){this.element=e},contentRef:function(e){this.content=e}},computed:{containerClass:function(){return["p-virtualscroller",this.class,{"p-virtualscroller-inline":this.inline,"p-virtualscroller-both p-both-scroll":this.isBoth(),"p-virtualscroller-horizontal p-horizontal-scroll":this.isHorizontal()}]},contentClass:function(){return["p-virtualscroller-content",{"p-virtualscroller-loading":this.d_loading}]},loaderClass:function(){return["p-virtualscroller-loader",{"p-virtualscroller-loader-mask":!this.$slots.loader}]},loadedItems:function(){var e=this;return this.items&&!this.d_loading?this.isBoth()?this.items.slice(this.appendOnly?0:this.first.rows,this.last.rows).map(function(n){return e.columns?n:n.slice(e.appendOnly?0:e.first.cols,e.last.cols)}):this.isHorizontal()&&this.columns?this.items:this.items.slice(this.appendOnly?0:this.first,this.last):[]},loadedRows:function(){return this.d_loading?this.loaderDisabled?this.loaderArr:[]:this.loadedItems},loadedColumns:function(){if(this.columns){var e=this.isBoth(),n=this.isHorizontal();if(e||n)return this.d_loading&&this.loaderDisabled?e?this.loaderArr[0]:this.loaderArr:this.columns.slice(e?this.first.cols:this.first,e?this.last.cols:this.last)}return this.columns}},components:{SpinnerIcon:ln}},Fo=["tabindex"];function Ro(t,e,n,i,s,o){var c=le("SpinnerIcon");return t.disabled?(l(),d(J,{key:1},[_(t.$slots,"default"),_(t.$slots,"content",{items:t.items,rows:t.items,columns:o.loadedColumns})],64)):(l(),d("div",w({key:0,ref:o.elementRef,class:o.containerClass,tabindex:t.tabindex,style:t.style,onScroll:e[0]||(e[0]=function(){return o.onScroll&&o.onScroll.apply(o,arguments)})},t.ptmi("root")),[_(t.$slots,"content",{styleClass:o.contentClass,items:o.loadedItems,getItemOptions:o.getOptions,loading:s.d_loading,getLoaderOptions:o.getLoaderOptions,itemSize:t.itemSize,rows:o.loadedRows,columns:o.loadedColumns,contentRef:o.contentRef,spacerStyle:s.spacerStyle,contentStyle:s.contentStyle,vertical:o.isVertical(),horizontal:o.isHorizontal(),both:o.isBoth()},function(){return[f("div",w({ref:o.contentRef,class:o.contentClass,style:s.contentStyle},t.ptm("content")),[(l(!0),d(J,null,re(o.loadedItems,function(p,m){return _(t.$slots,"item",{key:m,item:p,options:o.getOptions(m)})}),128))],16)]}),t.showSpacer?(l(),d("div",w({key:0,class:"p-virtualscroller-spacer",style:s.spacerStyle},t.ptm("spacer")),null,16)):y("",!0),!t.loaderDisabled&&t.showLoader&&s.d_loading?(l(),d("div",w({key:1,class:o.loaderClass},t.ptm("loader")),[t.$slots&&t.$slots.loader?(l(!0),d(J,{key:0},re(s.loaderArr,function(p,m){return _(t.$slots,"loader",{key:m,options:o.getLoaderOptions(m,o.isBoth()&&{numCols:t.d_numItemsInViewport.cols})})}),128)):y("",!0),_(t.$slots,"loadingicon",{},function(){return[K(c,w({spin:"",class:"p-virtualscroller-loading-icon"},t.ptm("loadingIcon")),null,16)]})],16)):y("",!0)],16,Fo))}Cn.render=Ro;var jo=`
    .p-autocomplete {
        display: inline-flex;
    }

    .p-autocomplete-loader {
        position: absolute;
        top: 50%;
        margin-top: -0.5rem;
        inset-inline-end: dt('autocomplete.padding.x');
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-loader {
        inset-inline-end: calc(dt('autocomplete.dropdown.width') + dt('autocomplete.padding.x'));
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-input {
        flex: 1 1 auto;
        width: 1%;
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-input,
    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-input-multiple {
        border-start-end-radius: 0;
        border-end-end-radius: 0;
    }

    .p-autocomplete-dropdown {
        cursor: pointer;
        display: inline-flex;
        user-select: none;
        align-items: center;
        justify-content: center;
        overflow: hidden;
        position: relative;
        width: dt('autocomplete.dropdown.width');
        border-start-end-radius: dt('autocomplete.dropdown.border.radius');
        border-end-end-radius: dt('autocomplete.dropdown.border.radius');
        background: dt('autocomplete.dropdown.background');
        border: 1px solid dt('autocomplete.dropdown.border.color');
        border-inline-start: 0 none;
        color: dt('autocomplete.dropdown.color');
        transition:
            background dt('autocomplete.transition.duration'),
            color dt('autocomplete.transition.duration'),
            border-color dt('autocomplete.transition.duration'),
            outline-color dt('autocomplete.transition.duration'),
            box-shadow dt('autocomplete.transition.duration');
        outline-color: transparent;
    }

    .p-autocomplete-dropdown:not(:disabled):hover {
        background: dt('autocomplete.dropdown.hover.background');
        border-color: dt('autocomplete.dropdown.hover.border.color');
        color: dt('autocomplete.dropdown.hover.color');
    }

    .p-autocomplete-dropdown:not(:disabled):active {
        background: dt('autocomplete.dropdown.active.background');
        border-color: dt('autocomplete.dropdown.active.border.color');
        color: dt('autocomplete.dropdown.active.color');
    }

    .p-autocomplete-dropdown:focus-visible {
        box-shadow: dt('autocomplete.dropdown.focus.ring.shadow');
        outline: dt('autocomplete.dropdown.focus.ring.width') dt('autocomplete.dropdown.focus.ring.style') dt('autocomplete.dropdown.focus.ring.color');
        outline-offset: dt('autocomplete.dropdown.focus.ring.offset');
    }

    .p-autocomplete-overlay {
        position: absolute;
        top: 0;
        left: 0;
        background: dt('autocomplete.overlay.background');
        color: dt('autocomplete.overlay.color');
        border: 1px solid dt('autocomplete.overlay.border.color');
        border-radius: dt('autocomplete.overlay.border.radius');
        box-shadow: dt('autocomplete.overlay.shadow');
        min-width: 100%;
    }

    .p-autocomplete-list-container {
        overflow: auto;
    }

    .p-autocomplete-list {
        margin: 0;
        list-style-type: none;
        display: flex;
        flex-direction: column;
        gap: dt('autocomplete.list.gap');
        padding: dt('autocomplete.list.padding');
    }

    .p-autocomplete-option {
        cursor: pointer;
        white-space: nowrap;
        position: relative;
        overflow: hidden;
        display: flex;
        align-items: center;
        padding: dt('autocomplete.option.padding');
        border: 0 none;
        color: dt('autocomplete.option.color');
        background: transparent;
        transition:
            background dt('autocomplete.transition.duration'),
            color dt('autocomplete.transition.duration'),
            border-color dt('autocomplete.transition.duration');
        border-radius: dt('autocomplete.option.border.radius');
    }

    .p-autocomplete-option:not(.p-autocomplete-option-selected):not(.p-disabled).p-focus {
        background: dt('autocomplete.option.focus.background');
        color: dt('autocomplete.option.focus.color');
    }

    .p-autocomplete-option:not(.p-autocomplete-option-selected):not(.p-disabled):hover {
        background: dt('autocomplete.option.focus.background');
        color: dt('autocomplete.option.focus.color');
    }

    .p-autocomplete-option-selected {
        background: dt('autocomplete.option.selected.background');
        color: dt('autocomplete.option.selected.color');
    }

    .p-autocomplete-option-selected.p-focus {
        background: dt('autocomplete.option.selected.focus.background');
        color: dt('autocomplete.option.selected.focus.color');
    }

    .p-autocomplete-option-group {
        margin: 0;
        padding: dt('autocomplete.option.group.padding');
        color: dt('autocomplete.option.group.color');
        background: dt('autocomplete.option.group.background');
        font-weight: dt('autocomplete.option.group.font.weight');
    }

    .p-autocomplete-input-multiple {
        margin: 0;
        list-style-type: none;
        cursor: text;
        overflow: hidden;
        display: flex;
        align-items: center;
        flex-wrap: wrap;
        padding: calc(dt('autocomplete.padding.y') / 2) dt('autocomplete.padding.x');
        gap: calc(dt('autocomplete.padding.y') / 2);
        color: dt('autocomplete.color');
        background: dt('autocomplete.background');
        border: 1px solid dt('autocomplete.border.color');
        border-radius: dt('autocomplete.border.radius');
        width: 100%;
        transition:
            background dt('autocomplete.transition.duration'),
            color dt('autocomplete.transition.duration'),
            border-color dt('autocomplete.transition.duration'),
            outline-color dt('autocomplete.transition.duration'),
            box-shadow dt('autocomplete.transition.duration');
        outline-color: transparent;
        box-shadow: dt('autocomplete.shadow');
    }

    .p-autocomplete-input-multiple.p-disabled {
        opacity: 1;
        background: dt('autocomplete.disabled.background');
        color: dt('autocomplete.disabled.color');
    }

    .p-autocomplete-input-multiple:not(.p-disabled):hover {
        border-color: dt('autocomplete.hover.border.color');
    }

    .p-autocomplete.p-focus .p-autocomplete-input-multiple:not(.p-disabled) {
        border-color: dt('autocomplete.focus.border.color');
        box-shadow: dt('autocomplete.focus.ring.shadow');
        outline: dt('autocomplete.focus.ring.width') dt('autocomplete.focus.ring.style') dt('autocomplete.focus.ring.color');
        outline-offset: dt('autocomplete.focus.ring.offset');
    }

    .p-autocomplete.p-invalid .p-autocomplete-input-multiple {
        border-color: dt('autocomplete.invalid.border.color');
    }

    .p-variant-filled.p-autocomplete-input-multiple {
        background: dt('autocomplete.filled.background');
    }

    .p-autocomplete-input-multiple.p-variant-filled:not(.p-disabled):hover {
        background: dt('autocomplete.filled.hover.background');
    }

    .p-autocomplete.p-focus .p-autocomplete-input-multiple.p-variant-filled:not(.p-disabled) {
        background: dt('autocomplete.filled.focus.background');
    }

    .p-autocomplete-chip.p-chip {
        padding-block-start: calc(dt('autocomplete.padding.y') / 2);
        padding-block-end: calc(dt('autocomplete.padding.y') / 2);
        border-radius: dt('autocomplete.chip.border.radius');
    }

    .p-autocomplete-input-multiple:has(.p-autocomplete-chip) {
        padding-inline-start: calc(dt('autocomplete.padding.y') / 2);
        padding-inline-end: calc(dt('autocomplete.padding.y') / 2);
    }

    .p-autocomplete-chip-item.p-focus .p-autocomplete-chip {
        background: dt('autocomplete.chip.focus.background');
        color: dt('autocomplete.chip.focus.color');
    }

    .p-autocomplete-input-chip {
        flex: 1 1 auto;
        display: inline-flex;
        padding-block-start: calc(dt('autocomplete.padding.y') / 2);
        padding-block-end: calc(dt('autocomplete.padding.y') / 2);
    }

    .p-autocomplete-input-chip input {
        border: 0 none;
        outline: 0 none;
        background: transparent;
        margin: 0;
        padding: 0;
        box-shadow: none;
        border-radius: 0;
        width: 100%;
        font-family: inherit;
        font-feature-settings: inherit;
        font-size: 1rem;
        color: inherit;
    }

    .p-autocomplete-input-chip input::placeholder {
        color: dt('autocomplete.placeholder.color');
    }

    .p-autocomplete.p-invalid .p-autocomplete-input-chip input::placeholder {
        color: dt('autocomplete.invalid.placeholder.color');
    }

    .p-autocomplete-empty-message {
        padding: dt('autocomplete.empty.message.padding');
    }

    .p-autocomplete-fluid {
        display: flex;
    }

    .p-autocomplete-fluid:has(.p-autocomplete-dropdown) .p-autocomplete-input {
        width: 1%;
    }

    .p-autocomplete:has(.p-inputtext-sm) .p-autocomplete-dropdown {
        width: dt('autocomplete.dropdown.sm.width');
    }

    .p-autocomplete:has(.p-inputtext-sm) .p-autocomplete-dropdown .p-icon {
        font-size: dt('form.field.sm.font.size');
        width: dt('form.field.sm.font.size');
        height: dt('form.field.sm.font.size');
    }

    .p-autocomplete:has(.p-inputtext-lg) .p-autocomplete-dropdown {
        width: dt('autocomplete.dropdown.lg.width');
    }

    .p-autocomplete:has(.p-inputtext-lg) .p-autocomplete-dropdown .p-icon {
        font-size: dt('form.field.lg.font.size');
        width: dt('form.field.lg.font.size');
        height: dt('form.field.lg.font.size');
    }

    .p-autocomplete-clear-icon {
        position: absolute;
        top: 50%;
        margin-top: -0.5rem;
        cursor: pointer;
        color: dt('form.field.icon.color');
        inset-inline-end: dt('autocomplete.padding.x');
    }

    .p-autocomplete:has(.p-autocomplete-dropdown) .p-autocomplete-clear-icon {
        inset-inline-end: calc(dt('autocomplete.padding.x') + dt('autocomplete.dropdown.width'));
    }

    .p-autocomplete:has(.p-autocomplete-clear-icon) .p-autocomplete-input {
        padding-inline-end: calc((dt('form.field.padding.x') * 2) + dt('icon.size'));
    }

    .p-inputgroup .p-autocomplete-dropdown {
        border-radius: 0;
    }

    .p-inputgroup > .p-autocomplete:last-child:has(.p-autocomplete-dropdown) > .p-autocomplete-input {
        border-start-end-radius: 0;
        border-end-end-radius: 0;
    }

    .p-inputgroup > .p-autocomplete:last-child .p-autocomplete-dropdown {
        border-start-end-radius: dt('autocomplete.dropdown.border.radius');
        border-end-end-radius: dt('autocomplete.dropdown.border.radius');
    }
`,Ko={root:{position:"relative"}},Ho={root:function(e){var n=e.instance;return["p-autocomplete p-component p-inputwrapper",{"p-invalid":n.$invalid,"p-focus":n.focused,"p-inputwrapper-filled":n.$filled||fe(n.inputValue),"p-inputwrapper-focus":n.focused,"p-autocomplete-open":n.overlayVisible,"p-autocomplete-fluid":n.$fluid,"p-autocomplete-clearable":n.isClearIconVisible}]},pcInputText:"p-autocomplete-input",inputMultiple:function(e){var n=e.instance,i=e.props;return["p-autocomplete-input-multiple",{"p-variant-filled":n.$variant==="filled","p-disabled":i.disabled}]},clearIcon:"p-autocomplete-clear-icon",chipItem:function(e){var n=e.instance,i=e.i;return["p-autocomplete-chip-item",{"p-focus":n.focusedMultipleOptionIndex===i}]},pcChip:"p-autocomplete-chip",chipIcon:"p-autocomplete-chip-icon",inputChip:"p-autocomplete-input-chip",loader:"p-autocomplete-loader",dropdown:"p-autocomplete-dropdown",overlay:"p-autocomplete-overlay p-component",listContainer:"p-autocomplete-list-container",list:"p-autocomplete-list",optionGroup:"p-autocomplete-option-group",option:function(e){var n=e.instance,i=e.option,s=e.i,o=e.getItemOptions;return["p-autocomplete-option",{"p-autocomplete-option-selected":n.isSelected(i),"p-focus":n.focusedOptionIndex===n.getOptionIndex(s,o),"p-disabled":n.isOptionDisabled(i)}]},emptyMessage:"p-autocomplete-empty-message"},No=he.extend({name:"autocomplete",style:jo,classes:Ho,inlineStyles:Ko}),Uo={name:"BaseAutoComplete",extends:bn,props:{suggestions:{type:Array,default:null},optionLabel:null,optionDisabled:null,optionGroupLabel:null,optionGroupChildren:null,scrollHeight:{type:String,default:"14rem"},dropdown:{type:Boolean,default:!1},dropdownMode:{type:String,default:"blank"},multiple:{type:Boolean,default:!1},loading:{type:Boolean,default:!1},placeholder:{type:String,default:null},dataKey:{type:String,default:null},minLength:{type:Number,default:1},delay:{type:Number,default:300},appendTo:{type:[String,Object],default:"body"},forceSelection:{type:Boolean,default:!1},completeOnFocus:{type:Boolean,default:!1},showClear:{type:Boolean,default:!1},inputId:{type:String,default:null},inputStyle:{type:Object,default:null},inputClass:{type:[String,Object],default:null},panelStyle:{type:Object,default:null},panelClass:{type:[String,Object],default:null},overlayStyle:{type:Object,default:null},overlayClass:{type:[String,Object],default:null},dropdownIcon:{type:String,default:null},dropdownClass:{type:[String,Object],default:null},loader:{type:String,default:null},loadingIcon:{type:String,default:null},removeTokenIcon:{type:String,default:null},chipIcon:{type:String,default:null},virtualScrollerOptions:{type:Object,default:null},autoOptionFocus:{type:Boolean,default:!1},selectOnFocus:{type:Boolean,default:!1},focusOnHover:{type:Boolean,default:!0},searchLocale:{type:String,default:void 0},searchMessage:{type:String,default:null},selectionMessage:{type:String,default:null},emptySelectionMessage:{type:String,default:null},emptySearchMessage:{type:String,default:null},showEmptyMessage:{type:Boolean,default:!0},tabindex:{type:Number,default:0},typeahead:{type:Boolean,default:!0},ariaLabel:{type:String,default:null},ariaLabelledby:{type:String,default:null}},style:No,provide:function(){return{$pcAutoComplete:this,$parentInstance:this}}};function Zt(t,e,n){return(e=Wo(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Wo(t){var e=Go(t,"string");return Oe(e)=="symbol"?e:e+""}function Go(t,e){if(Oe(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Oe(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}function Oe(t){"@babel/helpers - typeof";return Oe=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Oe(t)}function Qe(t){return Jo(t)||Xo(t)||Yo(t)||Zo()}function Zo(){throw new TypeError(`Invalid attempt to spread non-iterable instance.
In order to be iterable, non-array objects must have a [Symbol.iterator]() method.`)}function Yo(t,e){if(t){if(typeof t=="string")return mt(t,e);var n={}.toString.call(t).slice(8,-1);return n==="Object"&&t.constructor&&(n=t.constructor.name),n==="Map"||n==="Set"?Array.from(t):n==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?mt(t,e):void 0}}function Xo(t){if(typeof Symbol<"u"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function Jo(t){if(Array.isArray(t))return mt(t)}function mt(t,e){(e==null||e>t.length)&&(e=t.length);for(var n=0,i=Array(e);n<e;n++)i[n]=t[n];return i}var Sn={name:"AutoComplete",extends:Uo,inheritAttrs:!1,emits:["change","focus","blur","item-select","item-unselect","option-select","option-unselect","dropdown-click","clear","complete","before-show","before-hide","show","hide"],inject:{$pcFluid:{default:null}},outsideClickListener:null,resizeListener:null,scrollHandler:null,overlay:null,virtualScroller:null,searchTimeout:null,dirty:!1,startRangeIndex:-1,data:function(){return{clicked:!1,focused:!1,focusedOptionIndex:-1,focusedMultipleOptionIndex:-1,overlayVisible:!1,searching:!1}},watch:{suggestions:function(){this.searching&&(this.show(),this.focusedOptionIndex=this.overlayVisible&&this.autoOptionFocus?this.findFirstFocusedOptionIndex():-1,this.searching=!1,!this.showEmptyMessage&&this.visibleOptions.length===0&&this.hide()),this.autoUpdateModel()}},mounted:function(){this.autoUpdateModel()},updated:function(){this.overlayVisible&&this.alignOverlay()},beforeUnmount:function(){this.unbindOutsideClickListener(),this.unbindResizeListener(),this.scrollHandler&&(this.scrollHandler.destroy(),this.scrollHandler=null),this.overlay&&(ke.clear(this.overlay),this.overlay=null)},methods:{getOptionIndex:function(e,n){return this.virtualScrollerDisabled?e:n&&n(e).index},getOptionLabel:function(e){return this.optionLabel?Pe(e,this.optionLabel):e},getOptionValue:function(e){return e},getOptionRenderKey:function(e,n){return(this.dataKey?Pe(e,this.dataKey):this.getOptionLabel(e))+"_"+n},getPTOptions:function(e,n,i,s){return this.ptm(s,{context:{option:e,index:i,selected:this.isSelected(e),focused:this.focusedOptionIndex===this.getOptionIndex(i,n),disabled:this.isOptionDisabled(e)}})},isOptionDisabled:function(e){return this.optionDisabled?Pe(e,this.optionDisabled):!1},isOptionGroup:function(e){return this.optionGroupLabel&&e.optionGroup&&e.group},getOptionGroupLabel:function(e){return Pe(e,this.optionGroupLabel)},getOptionGroupChildren:function(e){return Pe(e,this.optionGroupChildren)},getAriaPosInset:function(e){var n=this;return(this.optionGroupLabel?e-this.visibleOptions.slice(0,e).filter(function(i){return n.isOptionGroup(i)}).length:e)+1},show:function(e){this.$emit("before-show"),this.dirty=!0,this.overlayVisible=!0,this.focusedOptionIndex=this.focusedOptionIndex!==-1?this.focusedOptionIndex:this.autoOptionFocus?this.findFirstFocusedOptionIndex():-1,e&&ie(this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el)},hide:function(e){var n=this,i=function(){var o;n.$emit("before-hide"),n.dirty=e,n.overlayVisible=!1,n.clicked=!1,n.focusedOptionIndex=-1,e&&ie(n.multiple?n.$refs.focusInput:(o=n.$refs.focusInput)===null||o===void 0?void 0:o.$el)};setTimeout(function(){i()},0)},onFocus:function(e){this.disabled||(!this.dirty&&this.completeOnFocus&&this.search(e,e.target.value,"focus"),this.dirty=!0,this.focused=!0,this.overlayVisible&&(this.focusedOptionIndex=this.focusedOptionIndex!==-1?this.focusedOptionIndex:this.overlayVisible&&this.autoOptionFocus?this.findFirstFocusedOptionIndex():-1,this.scrollInView(this.focusedOptionIndex)),this.$emit("focus",e))},onBlur:function(e){var n,i;this.dirty=!1,this.focused=!1,this.focusedOptionIndex=-1,this.$emit("blur",e),(n=(i=this.formField).onBlur)===null||n===void 0||n.call(i)},onKeyDown:function(e){if(this.disabled){e.preventDefault();return}switch(e.code){case"ArrowDown":this.onArrowDownKey(e);break;case"ArrowUp":this.onArrowUpKey(e);break;case"ArrowLeft":this.onArrowLeftKey(e);break;case"ArrowRight":this.onArrowRightKey(e);break;case"Home":this.onHomeKey(e);break;case"End":this.onEndKey(e);break;case"PageDown":this.onPageDownKey(e);break;case"PageUp":this.onPageUpKey(e);break;case"Enter":case"NumpadEnter":this.onEnterKey(e);break;case"Space":this.onSpaceKey(e);break;case"Escape":this.onEscapeKey(e);break;case"Tab":this.onTabKey(e);break;case"ShiftLeft":case"ShiftRight":this.onShiftKey(e);break;case"Backspace":this.onBackspaceKey(e);break}this.clicked=!1},onInput:function(e){var n=this;if(this.typeahead){this.searchTimeout&&clearTimeout(this.searchTimeout);var i=e.target.value;this.multiple||this.updateModel(e,i),i.length===0?(this.searching=!1,this.hide(),this.$emit("clear")):i.length>=this.minLength?(this.focusedOptionIndex=-1,this.searchTimeout=setTimeout(function(){n.search(e,i,"input")},this.delay)):(this.searching=!1,this.hide())}},onChange:function(e){var n=this;if(this.forceSelection){var i=!1;if(this.visibleOptions&&!this.multiple){var s,o=this.multiple?this.$refs.focusInput.value:(s=this.$refs.focusInput)===null||s===void 0||(s=s.$el)===null||s===void 0?void 0:s.value,c=this.visibleOptions.find(function(g){return n.isOptionMatched(g,o||"")});c!==void 0&&(i=!0,!this.isSelected(c)&&this.onOptionSelect(e,c))}if(!i){if(this.multiple)this.$refs.focusInput.value="";else{var p,m=(p=this.$refs.focusInput)===null||p===void 0?void 0:p.$el;m&&(m.value="")}this.$emit("clear"),!this.multiple&&this.updateModel(e,null)}}},onMultipleContainerFocus:function(){this.disabled||(this.focused=!0)},onMultipleContainerBlur:function(){this.focusedMultipleOptionIndex=-1,this.focused=!1},onMultipleContainerKeyDown:function(e){if(this.disabled){e.preventDefault();return}switch(e.code){case"ArrowLeft":this.onArrowLeftKeyOnMultiple(e);break;case"ArrowRight":this.onArrowRightKeyOnMultiple(e);break;case"Backspace":this.onBackspaceKeyOnMultiple(e);break}},onContainerClick:function(e){this.clicked=!0,!(this.disabled||this.searching||this.loading||this.isDropdownClicked(e))&&(!this.overlay||!this.overlay.contains(e.target))&&ie(this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el)},onDropdownClick:function(e){var n=void 0;if(this.overlayVisible)this.hide(!0);else{var i=this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el;ie(i),n=i.value,this.dropdownMode==="blank"?this.search(e,"","dropdown"):this.dropdownMode==="current"&&this.search(e,n,"dropdown")}this.$emit("dropdown-click",{originalEvent:e,query:n})},onOptionSelect:function(e,n){var i=arguments.length>2&&arguments[2]!==void 0?arguments[2]:!0,s=this.getOptionValue(n);this.multiple?(this.$refs.focusInput.value="",this.isSelected(n)||this.updateModel(e,[].concat(Qe(this.d_value||[]),[s]))):this.updateModel(e,s),this.$emit("item-select",{originalEvent:e,value:n}),this.$emit("option-select",{originalEvent:e,value:n}),i&&this.hide(!0)},onOptionMouseMove:function(e,n){this.focusOnHover&&this.changeFocusedOptionIndex(e,n)},onOptionSelectRange:function(e){var n=this,i=arguments.length>1&&arguments[1]!==void 0?arguments[1]:-1,s=arguments.length>2&&arguments[2]!==void 0?arguments[2]:-1;if(i===-1&&(i=this.findNearestSelectedOptionIndex(s,!0)),s===-1&&(s=this.findNearestSelectedOptionIndex(i)),i!==-1&&s!==-1){var o=Math.min(i,s),c=Math.max(i,s),p=this.visibleOptions.slice(o,c+1).filter(function(m){return n.isValidOption(m)}).filter(function(m){return!n.isSelected(m)}).map(function(m){return n.getOptionValue(m)});this.updateModel(e,[].concat(Qe(this.d_value||[]),Qe(p)))}},onClearClick:function(e){this.updateModel(e,null),this.$emit("clear")},onOverlayClick:function(e){Mo.emit("overlay-click",{originalEvent:e,target:this.$el})},onOverlayKeyDown:function(e){switch(e.code){case"Escape":this.onEscapeKey(e);break}},onArrowDownKey:function(e){if(this.overlayVisible){var n=this.focusedOptionIndex!==-1?this.findNextOptionIndex(this.focusedOptionIndex):this.clicked?this.findFirstOptionIndex():this.findFirstFocusedOptionIndex();this.multiple&&e.shiftKey&&this.onOptionSelectRange(e,this.startRangeIndex,n),this.changeFocusedOptionIndex(e,n),e.preventDefault()}},onArrowUpKey:function(e){if(this.overlayVisible)if(e.altKey)this.focusedOptionIndex!==-1&&this.onOptionSelect(e,this.visibleOptions[this.focusedOptionIndex]),this.overlayVisible&&this.hide(),e.preventDefault();else{var n=this.focusedOptionIndex!==-1?this.findPrevOptionIndex(this.focusedOptionIndex):this.clicked?this.findLastOptionIndex():this.findLastFocusedOptionIndex();this.multiple&&e.shiftKey&&this.onOptionSelectRange(e,n,this.startRangeIndex),this.changeFocusedOptionIndex(e,n),e.preventDefault()}},onArrowLeftKey:function(e){var n=e.currentTarget;this.focusedOptionIndex=-1,this.multiple&&(ni(n.value)&&this.$filled?(ie(this.$refs.multiContainer),this.focusedMultipleOptionIndex=this.d_value.length):e.stopPropagation())},onArrowRightKey:function(e){this.focusedOptionIndex=-1,this.multiple&&e.stopPropagation()},onHomeKey:function(e){var n=e.currentTarget,i=n.value.length,s=e.metaKey||e.ctrlKey,o=this.findFirstOptionIndex();this.multiple&&e.shiftKey&&s&&this.onOptionSelectRange(e,o,this.startRangeIndex),n.setSelectionRange(0,e.shiftKey?i:0),this.focusedOptionIndex=-1,e.preventDefault()},onEndKey:function(e){var n=e.currentTarget,i=n.value.length,s=e.metaKey||e.ctrlKey,o=this.findLastOptionIndex();this.multiple&&e.shiftKey&&s&&this.onOptionSelectRange(e,this.startRangeIndex,o),n.setSelectionRange(e.shiftKey?0:i,i),this.focusedOptionIndex=-1,e.preventDefault()},onPageUpKey:function(e){this.scrollInView(0),e.preventDefault()},onPageDownKey:function(e){this.scrollInView(this.visibleOptions.length-1),e.preventDefault()},onEnterKey:function(e){this.typeahead?this.overlayVisible?(this.focusedOptionIndex!==-1&&(this.multiple&&e.shiftKey?this.onOptionSelectRange(e,this.focusedOptionIndex):this.onOptionSelect(e,this.visibleOptions[this.focusedOptionIndex]),e.preventDefault()),this.hide()):(this.focusedOptionIndex=-1,this.onArrowDownKey(e)):this.multiple&&(e.target.value.trim()&&(this.updateModel(e,[].concat(Qe(this.d_value||[]),[e.target.value.trim()])),this.$refs.focusInput.value=""),e.preventDefault())},onSpaceKey:function(e){!this.autoOptionFocus&&this.focusedOptionIndex!==-1&&this.onEnterKey(e)},onEscapeKey:function(e){this.overlayVisible&&this.hide(!0),e.preventDefault()},onTabKey:function(e){this.focusedOptionIndex!==-1&&this.onOptionSelect(e,this.visibleOptions[this.focusedOptionIndex]),this.overlayVisible&&this.hide()},onShiftKey:function(){this.startRangeIndex=this.focusedOptionIndex},onBackspaceKey:function(e){if(this.multiple){if(fe(this.d_value)&&!this.$refs.focusInput.value){var n=this.d_value[this.d_value.length-1],i=this.d_value.slice(0,-1);this.writeValue(i,e),this.$emit("item-unselect",{originalEvent:e,value:n}),this.$emit("option-unselect",{originalEvent:e,value:n})}e.stopPropagation()}},onArrowLeftKeyOnMultiple:function(){this.focusedMultipleOptionIndex=this.focusedMultipleOptionIndex<1?0:this.focusedMultipleOptionIndex-1},onArrowRightKeyOnMultiple:function(){this.focusedMultipleOptionIndex++,this.focusedMultipleOptionIndex>this.d_value.length-1&&(this.focusedMultipleOptionIndex=-1,ie(this.$refs.focusInput))},onBackspaceKeyOnMultiple:function(e){this.focusedMultipleOptionIndex!==-1&&this.removeOption(e,this.focusedMultipleOptionIndex)},onOverlayEnter:function(e){ke.set("overlay",e,this.$primevue.config.zIndex.overlay),rn(e,{position:"absolute",top:"0"}),this.alignOverlay(),this.$attrSelector&&e.setAttribute(this.$attrSelector,"")},onOverlayAfterEnter:function(){this.bindOutsideClickListener(),this.bindScrollListener(),this.bindResizeListener(),this.$emit("show")},onOverlayLeave:function(e){e.style.pointerEvents="none",this.unbindOutsideClickListener(),this.unbindScrollListener(),this.unbindResizeListener(),this.$emit("hide"),this.overlay=null},onOverlayAfterLeave:function(e){ke.clear(e)},alignOverlay:function(){var e=this.multiple?this.$refs.multiContainer:this.$refs.focusInput.$el;this.appendTo==="self"?ei(this.overlay,e):(this.overlay.style.minWidth=an(e)+"px",ti(this.overlay,e))},bindOutsideClickListener:function(){var e=this;this.outsideClickListener||(this.outsideClickListener=function(n){e.overlayVisible&&e.overlay&&e.isOutsideClicked(n)&&e.hide()},document.addEventListener("click",this.outsideClickListener,!0))},unbindOutsideClickListener:function(){this.outsideClickListener&&(document.removeEventListener("click",this.outsideClickListener,!0),this.outsideClickListener=null)},bindScrollListener:function(){var e=this;this.scrollHandler||(this.scrollHandler=new no(this.$refs.container,function(){e.overlayVisible&&e.hide()})),this.scrollHandler.bindScrollListener()},unbindScrollListener:function(){this.scrollHandler&&this.scrollHandler.unbindScrollListener()},bindResizeListener:function(){var e=this;this.resizeListener||(this.resizeListener=function(){e.overlayVisible&&!qn()&&e.hide()},window.addEventListener("resize",this.resizeListener))},unbindResizeListener:function(){this.resizeListener&&(window.removeEventListener("resize",this.resizeListener),this.resizeListener=null)},isOutsideClicked:function(e){return!this.overlay.contains(e.target)&&!this.isInputClicked(e)&&!this.isDropdownClicked(e)},isInputClicked:function(e){return this.multiple?e.target===this.$refs.multiContainer||this.$refs.multiContainer.contains(e.target):e.target===this.$refs.focusInput.$el},isDropdownClicked:function(e){return this.$refs.dropdownButton?e.target===this.$refs.dropdownButton||this.$refs.dropdownButton.contains(e.target):!1},isOptionMatched:function(e,n){var i;return this.isValidOption(e)&&((i=this.getOptionLabel(e))===null||i===void 0?void 0:i.toLocaleLowerCase(this.searchLocale))===n.toLocaleLowerCase(this.searchLocale)},isValidOption:function(e){return fe(e)&&!(this.isOptionDisabled(e)||this.isOptionGroup(e))},isValidSelectedOption:function(e){return this.isValidOption(e)&&this.isSelected(e)},isEquals:function(e,n){return Qn(e,n,this.equalityKey)},isSelected:function(e){var n=this,i=this.getOptionValue(e);return this.multiple?(this.d_value||[]).some(function(s){return n.isEquals(s,i)}):this.isEquals(this.d_value,this.getOptionValue(e))},findFirstOptionIndex:function(){var e=this;return this.visibleOptions.findIndex(function(n){return e.isValidOption(n)})},findLastOptionIndex:function(){var e=this;return lt(this.visibleOptions,function(n){return e.isValidOption(n)})},findNextOptionIndex:function(e){var n=this,i=e<this.visibleOptions.length-1?this.visibleOptions.slice(e+1).findIndex(function(s){return n.isValidOption(s)}):-1;return i>-1?i+e+1:e},findPrevOptionIndex:function(e){var n=this,i=e>0?lt(this.visibleOptions.slice(0,e),function(s){return n.isValidOption(s)}):-1;return i>-1?i:e},findSelectedOptionIndex:function(){var e=this;return this.$filled?this.visibleOptions.findIndex(function(n){return e.isValidSelectedOption(n)}):-1},findFirstFocusedOptionIndex:function(){var e=this.findSelectedOptionIndex();return e<0?this.findFirstOptionIndex():e},findLastFocusedOptionIndex:function(){var e=this.findSelectedOptionIndex();return e<0?this.findLastOptionIndex():e},search:function(e,n,i){n!=null&&(i==="input"&&n.trim().length===0||(this.searching=!0,this.$emit("complete",{originalEvent:e,query:n})))},removeOption:function(e,n){var i=this,s=this.d_value[n],o=this.d_value.filter(function(c,p){return p!==n}).map(function(c){return i.getOptionValue(c)});this.updateModel(e,o),this.$emit("item-unselect",{originalEvent:e,value:s}),this.$emit("option-unselect",{originalEvent:e,value:s}),this.dirty=!0,ie(this.multiple?this.$refs.focusInput:this.$refs.focusInput.$el)},changeFocusedOptionIndex:function(e,n){this.focusedOptionIndex!==n&&(this.focusedOptionIndex=n,this.scrollInView(),this.selectOnFocus&&this.onOptionSelect(e,this.visibleOptions[n],!1))},scrollInView:function(){var e=this,n=arguments.length>0&&arguments[0]!==void 0?arguments[0]:-1;this.$nextTick(function(){var i=n!==-1?"".concat(e.$id,"_").concat(n):e.focusedOptionId,s=un(e.list,'li[id="'.concat(i,'"]'));s?s.scrollIntoView&&s.scrollIntoView({block:"nearest",inline:"start"}):e.virtualScrollerDisabled||e.virtualScroller&&e.virtualScroller.scrollToIndex(n!==-1?n:e.focusedOptionIndex)})},autoUpdateModel:function(){this.selectOnFocus&&this.autoOptionFocus&&!this.$filled&&(this.focusedOptionIndex=this.findFirstFocusedOptionIndex(),this.onOptionSelect(null,this.visibleOptions[this.focusedOptionIndex],!1))},updateModel:function(e,n){this.writeValue(n,e),this.$emit("change",{originalEvent:e,value:n})},flatOptions:function(e){var n=this;return(e||[]).reduce(function(i,s,o){i.push({optionGroup:s,group:!0,index:o});var c=n.getOptionGroupChildren(s);return c&&c.forEach(function(p){return i.push(p)}),i},[])},overlayRef:function(e){this.overlay=e},listRef:function(e,n){this.list=e,n&&n(e)},virtualScrollerRef:function(e){this.virtualScroller=e},findNextSelectedOptionIndex:function(e){var n=this,i=this.$filled&&e<this.visibleOptions.length-1?this.visibleOptions.slice(e+1).findIndex(function(s){return n.isValidSelectedOption(s)}):-1;return i>-1?i+e+1:-1},findPrevSelectedOptionIndex:function(e){var n=this,i=this.$filled&&e>0?lt(this.visibleOptions.slice(0,e),function(s){return n.isValidSelectedOption(s)}):-1;return i>-1?i:-1},findNearestSelectedOptionIndex:function(e){var n=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,i=-1;return this.$filled&&(n?(i=this.findPrevSelectedOptionIndex(e),i=i===-1?this.findNextSelectedOptionIndex(e):i):(i=this.findNextSelectedOptionIndex(e),i=i===-1?this.findPrevSelectedOptionIndex(e):i)),i>-1?i:e}},computed:{visibleOptions:function(){return this.optionGroupLabel?this.flatOptions(this.suggestions):this.suggestions||[]},inputValue:function(){if(this.$filled)if(Oe(this.d_value)==="object"){var e=this.getOptionLabel(this.d_value);return e??this.d_value}else return this.d_value;else return""},hasSelectedOption:function(){return this.$filled},equalityKey:function(){return this.dataKey},searchResultMessageText:function(){return fe(this.visibleOptions)&&this.overlayVisible?this.searchMessageText.replaceAll("{0}",this.visibleOptions.length):this.emptySearchMessageText},searchMessageText:function(){return this.searchMessage||this.$primevue.config.locale.searchMessage||""},emptySearchMessageText:function(){return this.emptySearchMessage||this.$primevue.config.locale.emptySearchMessage||""},selectionMessageText:function(){return this.selectionMessage||this.$primevue.config.locale.selectionMessage||""},emptySelectionMessageText:function(){return this.emptySelectionMessage||this.$primevue.config.locale.emptySelectionMessage||""},selectedMessageText:function(){return this.$filled?this.selectionMessageText.replaceAll("{0}",this.multiple?this.d_value.length:"1"):this.emptySelectionMessageText},listAriaLabel:function(){return this.$primevue.config.locale.aria?this.$primevue.config.locale.aria.listLabel:void 0},focusedOptionId:function(){return this.focusedOptionIndex!==-1?"".concat(this.$id,"_").concat(this.focusedOptionIndex):null},focusedMultipleOptionId:function(){return this.focusedMultipleOptionIndex!==-1?"".concat(this.$id,"_multiple_option_").concat(this.focusedMultipleOptionIndex):null},isClearIconVisible:function(){return this.showClear&&this.$filled&&!this.disabled&&!this.loading},ariaSetSize:function(){var e=this;return this.visibleOptions.filter(function(n){return!e.isOptionGroup(n)}).length},virtualScrollerDisabled:function(){return!this.virtualScrollerOptions},panelId:function(){return this.$id+"_panel"},containerDataP:function(){return me({fluid:this.$fluid})},overlayDataP:function(){return me(Zt({},"portal-"+this.appendTo,"portal-"+this.appendTo))},inputMultipleDataP:function(){return me(Zt({invalid:this.$invalid,disabled:this.disabled,focus:this.focused,fluid:this.$fluid,filled:this.$variant==="filled",empty:!this.$filled},this.size,this.size))}},components:{InputText:bt,VirtualScroller:Cn,Portal:yt,Chip:yn,ChevronDownIcon:gn,SpinnerIcon:ln,TimesIcon:et},directives:{ripple:vt}};function Fe(t){"@babel/helpers - typeof";return Fe=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Fe(t)}function Yt(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function Xt(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?Yt(Object(n),!0).forEach(function(i){Qo(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):Yt(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function Qo(t,e,n){return(e=qo(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function qo(t){var e=es(t,"string");return Fe(e)=="symbol"?e:e+""}function es(t,e){if(Fe(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Fe(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var ts=["data-p"],ns=["aria-activedescendant","data-p-has-dropdown","data-p"],is=["id","aria-label","aria-setsize","aria-posinset"],os=["id","placeholder","tabindex","disabled","aria-label","aria-labelledby","aria-expanded","aria-controls","aria-activedescendant","aria-invalid"],ss=["data-p-has-dropdown"],as=["disabled","aria-expanded","aria-controls"],rs=["id","data-p"],ls=["id","aria-label"],us=["id"],ds=["id","aria-label","aria-selected","aria-disabled","aria-setsize","aria-posinset","onClick","onMousemove","data-p-selected","data-p-focused","data-p-disabled"];function cs(t,e,n,i,s,o){var c=le("InputText"),p=le("TimesIcon"),m=le("Chip"),g=le("SpinnerIcon"),h=le("VirtualScroller"),b=le("Portal"),S=ht("ripple");return l(),d("div",w({ref:"container",class:t.cx("root"),style:t.sx("root"),onClick:e[11]||(e[11]=function(){return o.onContainerClick&&o.onContainerClick.apply(o,arguments)}),"data-p":o.containerDataP},t.ptmi("root")),[t.multiple?y("",!0):(l(),G(c,{key:0,ref:"focusInput",id:t.inputId,type:"text",name:t.$formName,class:ee([t.cx("pcInputText"),t.inputClass]),style:An(t.inputStyle),defaultValue:o.inputValue,placeholder:t.placeholder,tabindex:t.disabled?-1:t.tabindex,fluid:t.$fluid,disabled:t.disabled,size:t.size,invalid:t.invalid,variant:t.variant,autocomplete:"off",role:"combobox","aria-label":t.ariaLabel,"aria-labelledby":t.ariaLabelledby,"aria-haspopup":"listbox","aria-autocomplete":"list","aria-expanded":s.overlayVisible,"aria-controls":s.overlayVisible?o.panelId:void 0,"aria-activedescendant":s.focused?o.focusedOptionId:void 0,onFocus:o.onFocus,onBlur:o.onBlur,onKeydown:o.onKeyDown,onInput:o.onInput,onChange:o.onChange,unstyled:t.unstyled,"data-p-has-dropdown":t.dropdown,pt:t.ptm("pcInputText")},null,8,["id","name","class","style","defaultValue","placeholder","tabindex","fluid","disabled","size","invalid","variant","aria-label","aria-labelledby","aria-expanded","aria-controls","aria-activedescendant","onFocus","onBlur","onKeydown","onInput","onChange","unstyled","data-p-has-dropdown","pt"])),o.isClearIconVisible?_(t.$slots,"clearicon",{key:1,class:ee(t.cx("clearIcon")),clearCallback:o.onClearClick},function(){return[K(p,w({class:[t.cx("clearIcon")],onClick:o.onClearClick},t.ptm("clearIcon")),null,16,["class","onClick"])]}):y("",!0),t.multiple?(l(),d("ul",w({key:2,ref:"multiContainer",class:t.cx("inputMultiple"),tabindex:"-1",role:"listbox","aria-orientation":"horizontal","aria-activedescendant":s.focused?o.focusedMultipleOptionId:void 0,onFocus:e[5]||(e[5]=function(){return o.onMultipleContainerFocus&&o.onMultipleContainerFocus.apply(o,arguments)}),onBlur:e[6]||(e[6]=function(){return o.onMultipleContainerBlur&&o.onMultipleContainerBlur.apply(o,arguments)}),onKeydown:e[7]||(e[7]=function(){return o.onMultipleContainerKeyDown&&o.onMultipleContainerKeyDown.apply(o,arguments)}),"data-p-has-dropdown":t.dropdown,"data-p":o.inputMultipleDataP},t.ptm("inputMultiple")),[(l(!0),d(J,null,re(t.d_value,function(C,O){return l(),d("li",w({key:"".concat(O,"_").concat(o.getOptionLabel(C)),id:t.$id+"_multiple_option_"+O,class:t.cx("chipItem",{i:O}),role:"option","aria-label":o.getOptionLabel(C),"aria-selected":!0,"aria-setsize":t.d_value.length,"aria-posinset":O+1},{ref_for:!0},t.ptm("chipItem")),[_(t.$slots,"chip",w({class:t.cx("pcChip"),value:C,index:O,removeCallback:function(P){return o.removeOption(P,O)}},{ref_for:!0},t.ptm("pcChip")),function(){return[K(m,{class:ee(t.cx("pcChip")),label:o.getOptionLabel(C),removeIcon:t.chipIcon||t.removeTokenIcon,removable:"",unstyled:t.unstyled,onRemove:function(P){return o.removeOption(P,O)},"data-p-focused":s.focusedMultipleOptionIndex===O,pt:t.ptm("pcChip")},{removeicon:ne(function(){return[_(t.$slots,t.$slots.chipicon?"chipicon":"removetokenicon",{class:ee(t.cx("chipIcon")),index:O,removeCallback:function(P){return o.removeOption(P,O)}})]}),_:2},1032,["class","label","removeIcon","unstyled","onRemove","data-p-focused","pt"])]})],16,is)}),128)),f("li",w({class:t.cx("inputChip"),role:"option"},t.ptm("inputChip")),[f("input",w({ref:"focusInput",id:t.inputId,type:"text",style:t.inputStyle,class:t.inputClass,placeholder:t.placeholder,tabindex:t.disabled?-1:t.tabindex,disabled:t.disabled,autocomplete:"off",role:"combobox","aria-label":t.ariaLabel,"aria-labelledby":t.ariaLabelledby,"aria-haspopup":"listbox","aria-autocomplete":"list","aria-expanded":s.overlayVisible,"aria-controls":t.$id+"_list","aria-activedescendant":s.focused?o.focusedOptionId:void 0,"aria-invalid":t.invalid||void 0,onFocus:e[0]||(e[0]=function(){return o.onFocus&&o.onFocus.apply(o,arguments)}),onBlur:e[1]||(e[1]=function(){return o.onBlur&&o.onBlur.apply(o,arguments)}),onKeydown:e[2]||(e[2]=function(){return o.onKeyDown&&o.onKeyDown.apply(o,arguments)}),onInput:e[3]||(e[3]=function(){return o.onInput&&o.onInput.apply(o,arguments)}),onChange:e[4]||(e[4]=function(){return o.onChange&&o.onChange.apply(o,arguments)})},t.ptm("input")),null,16,os)],16)],16,ns)):y("",!0),s.searching||t.loading?_(t.$slots,t.$slots.loader?"loader":"loadingicon",{key:3,class:ee(t.cx("loader"))},function(){return[t.loader||t.loadingIcon?(l(),d("i",w({key:0,class:["pi-spin",t.cx("loader"),t.loader,t.loadingIcon],"aria-hidden":"true","data-p-has-dropdown":t.dropdown},t.ptm("loader")),null,16,ss)):t.loading?(l(),G(g,w({key:1,class:t.cx("loader"),spin:"","aria-hidden":"true","data-p-has-dropdown":t.dropdown},t.ptm("loader")),null,16,["class","data-p-has-dropdown"])):y("",!0)]}):y("",!0),_(t.$slots,t.$slots.dropdown?"dropdown":"dropdownbutton",{toggleCallback:function(O){return o.onDropdownClick(O)}},function(){return[t.dropdown?(l(),d("button",w({key:0,ref:"dropdownButton",type:"button",class:[t.cx("dropdown"),t.dropdownClass],disabled:t.disabled,"aria-haspopup":"listbox","aria-expanded":s.overlayVisible,"aria-controls":o.panelId,onClick:e[8]||(e[8]=function(){return o.onDropdownClick&&o.onDropdownClick.apply(o,arguments)})},t.ptm("dropdown")),[_(t.$slots,"dropdownicon",{class:ee(t.dropdownIcon)},function(){return[(l(),G(Ie(t.dropdownIcon?"span":"ChevronDownIcon"),w({class:t.dropdownIcon},t.ptm("dropdownIcon")),null,16,["class"]))]})],16,as)):y("",!0)]}),t.typeahead?(l(),d("span",w({key:4,role:"status","aria-live":"polite",class:"p-hidden-accessible"},t.ptm("hiddenSearchResult"),{"data-p-hidden-accessible":!0}),v(o.searchResultMessageText),17)):y("",!0),K(b,{appendTo:t.appendTo},{default:ne(function(){return[K(gt,w({name:"p-anchored-overlay",onEnter:o.onOverlayEnter,onAfterEnter:o.onOverlayAfterEnter,onLeave:o.onOverlayLeave,onAfterLeave:o.onOverlayAfterLeave},t.ptm("transition")),{default:ne(function(){return[s.overlayVisible?(l(),d("div",w({key:0,ref:o.overlayRef,id:o.panelId,class:[t.cx("overlay"),t.panelClass,t.overlayClass],style:Xt(Xt({},t.panelStyle),t.overlayStyle),onClick:e[9]||(e[9]=function(){return o.onOverlayClick&&o.onOverlayClick.apply(o,arguments)}),onKeydown:e[10]||(e[10]=function(){return o.onOverlayKeyDown&&o.onOverlayKeyDown.apply(o,arguments)}),"data-p":o.overlayDataP},t.ptm("overlay")),[_(t.$slots,"header",{value:t.d_value,suggestions:o.visibleOptions}),f("div",w({class:t.cx("listContainer"),style:{"max-height":o.virtualScrollerDisabled?t.scrollHeight:""}},t.ptm("listContainer")),[K(h,w({ref:o.virtualScrollerRef},t.virtualScrollerOptions,{style:{height:t.scrollHeight},items:o.visibleOptions,tabindex:-1,disabled:o.virtualScrollerDisabled,pt:t.ptm("virtualScroller")}),Dn({content:ne(function(C){var O=C.styleClass,L=C.contentRef,P=C.items,M=C.getItemOptions,A=C.contentStyle,j=C.itemSize;return[f("ul",w({ref:function(R){return o.listRef(R,L)},id:t.$id+"_list",class:[t.cx("list"),O],style:A,role:"listbox","aria-label":o.listAriaLabel},t.ptm("list")),[(l(!0),d(J,null,re(P,function(x,R){return l(),d(J,{key:o.getOptionRenderKey(x,o.getOptionIndex(R,M))},[o.isOptionGroup(x)?(l(),d("li",w({key:0,id:t.$id+"_"+o.getOptionIndex(R,M),style:{height:j?j+"px":void 0},class:t.cx("optionGroup"),role:"option"},{ref_for:!0},t.ptm("optionGroup")),[_(t.$slots,"optiongroup",{option:x.optionGroup,index:o.getOptionIndex(R,M)},function(){return[F(v(o.getOptionGroupLabel(x.optionGroup)),1)]})],16,us)):Se((l(),d("li",w({key:1,id:t.$id+"_"+o.getOptionIndex(R,M),style:{height:j?j+"px":void 0},class:t.cx("option",{option:x,i:R,getItemOptions:M}),role:"option","aria-label":o.getOptionLabel(x),"aria-selected":o.isSelected(x),"aria-disabled":o.isOptionDisabled(x),"aria-setsize":o.ariaSetSize,"aria-posinset":o.getAriaPosInset(o.getOptionIndex(R,M)),onClick:function(k){return o.onOptionSelect(k,x)},onMousemove:function(k){return o.onOptionMouseMove(k,o.getOptionIndex(R,M))},"data-p-selected":o.isSelected(x),"data-p-focused":s.focusedOptionIndex===o.getOptionIndex(R,M),"data-p-disabled":o.isOptionDisabled(x)},{ref_for:!0},o.getPTOptions(x,M,R,"option")),[_(t.$slots,"option",{option:x,index:o.getOptionIndex(R,M)},function(){return[F(v(o.getOptionLabel(x)),1)]})],16,ds)),[[S]])],64)}),128)),t.showEmptyMessage&&(!P||P&&P.length===0)?(l(),d("li",w({key:0,class:t.cx("emptyMessage"),role:"option"},t.ptm("emptyMessage")),[_(t.$slots,"empty",{},function(){return[F(v(o.searchResultMessageText),1)]})],16)):y("",!0)],16,ls)]}),_:2},[t.$slots.loader?{name:"loader",fn:ne(function(C){var O=C.options;return[_(t.$slots,"loader",{options:O})]}),key:"0"}:void 0]),1040,["style","items","disabled","pt"])],16),_(t.$slots,"footer",{value:t.d_value,suggestions:o.visibleOptions}),f("span",w({role:"status","aria-live":"polite",class:"p-hidden-accessible"},t.ptm("hiddenSelectedMessage"),{"data-p-hidden-accessible":!0}),v(o.selectedMessageText),17)],16,rs)):y("",!0)]}),_:3},16,["onEnter","onAfterEnter","onLeave","onAfterLeave"])]}),_:3},8,["appendTo"])],16,ts)}Sn.render=cs;function ue(t){return t===void 0?!0:typeof t=="string"?t.trim()==="":typeof t=="object"?Object.keys(t).length===0:!1}function Ce(t){return t===void 0?"":typeof t=="string"?t:JSON.stringify(t)}function ps(t,e){if(!e||e==="string"||t.trim()==="")return t;let n;try{n=JSON.parse(t)}catch{throw new Error(`Enter a valid ${e} as JSON`)}if(!(e==="array"?Array.isArray(n):e==="object"?n!==null&&typeof n=="object"&&!Array.isArray(n):e==="integer"?typeof n=="number"&&Number.isInteger(n):typeof n===e))throw new Error(`Enter a valid ${e} as JSON`);return n}const fs={class:"req-value"},ms={class:"req-value-option-main"},hs={class:"mono"},gs={class:"req-value-option-meta"},vs={key:2,role:"alert",class:"req-value-error"},ys=Ke({__name:"RequirementValueInput",props:{modelValue:{type:[String,Number,Boolean,Array,Object]},requirement:{},placeholder:{},disabled:{type:Boolean}},emits:["update:model-value","validity","commit"],setup(t,{emit:e}){const n=t,i=e,s=dn(),o=W(Ce(n.modelValue)),c=W([]),p=W(null),m=W(!1);let g=0,h,b=Ce(n.modelValue),S=b,C=!1;on(()=>n.modelValue,z=>{const k=Ce(z);o.value=k,k!==S&&(b=k,S=k,C=!1)});const O=Y(()=>!!n.requirement.expected_type),L=Y(()=>{const z=(n.requirement.suggestions||[]).filter($=>typeof $.value=="string"&&$.value!=="").map($=>({value:$.value,label:$.label||String($.value),source:$.source||"plan",kind:$.kind})),k=new Set(z.map($=>$.value)),D=n.requirement.expected_kind,H=c.value.filter($=>!D||$.kind===D||k.has($.id)).map($=>({value:$.id,label:$.meta?.title||$.id,source:"registry",kind:$.kind})),Q=new Set;return[...z,...H].filter($=>Q.has($.value)?!1:(Q.add($.value),!0)).slice(0,80)});function P(z){o.value=z;try{const k=ps(z,n.requirement.expected_type);S=Ce(k),C=S!==b,p.value=null,i("validity",!0),i("update:model-value",k)}catch(k){p.value=k instanceof Error?k.message:"Invalid requirement value",i("validity",!1)}O.value||(h&&clearTimeout(h),h=setTimeout(()=>{M()},180))}async function M(){if(O.value)return;const z=++g;m.value=!0,p.value=null;try{const k=await ii(s,{query:o.value.trim()||void 0,limit:80});z===g&&(c.value=k.entries||[])}catch(k){if(z!==g)return;c.value=[],p.value=k instanceof Error?k.message:"Registry search failed"}finally{z===g&&(m.value=!1)}}function A(){n.disabled||p.value||!C||(b=S,C=!1,i("commit"))}function j(z){n.disabled||P(typeof z=="string"?z:z.value)}function x(z){j(z.value),A()}function R(z){z.target instanceof Element&&z.target.getAttribute("aria-expanded")==="true"&&z.stopPropagation()}return Vn(()=>{g+=1,h&&clearTimeout(h)}),(z,k)=>(l(),d("div",fs,[O.value?(l(),G(N(bt),{key:0,"model-value":o.value,class:"req-value-input mono","aria-label":t.requirement.parameter_name,"aria-invalid":!!p.value,disabled:t.disabled,placeholder:t.placeholder||`Enter ${t.requirement.expected_type}`,"onUpdate:modelValue":k[0]||(k[0]=D=>P(D||"")),onChange:A,onBlur:A,onKeydown:rt(Tn(A,["prevent"]),["enter"])},null,8,["model-value","aria-label","aria-invalid","disabled","placeholder","onKeydown"])):(l(),G(N(Sn),{key:1,"model-value":o.value,suggestions:L.value,"option-label":"value",dropdown:"","complete-on-focus":"",delay:0,"min-length":0,loading:m.value,disabled:t.disabled,placeholder:t.placeholder||"Search registry or type value","input-props":{"aria-label":t.requirement.parameter_name},"input-class":"req-value-input mono",pt:{option:{class:"req-value-option"},dropdown:{"aria-label":"Show requirement candidates"}},"onUpdate:modelValue":j,onComplete:M,onOptionSelect:x,onChange:A,onBlur:A,onKeydown:[rt(A,["enter"]),rt(R,["esc"])]},{option:ne(({option:D})=>[f("span",ms,[f("span",null,v(D.label),1),f("span",hs,v(D.value),1),f("span",gs,v(D.kind||D.source),1)])]),_:1},8,["model-value","suggestions","loading","disabled","placeholder","input-props"])),p.value?(l(),d("p",vs,v(p.value),1)):y("",!0)]))}}),Jt=cn(ys,[["__scopeId","data-v-4d356663"]]),bs={key:0,class:"mt-1 text-[11px]",style:{color:"var(--p-text-color)"}},ws={class:"mono"},Cs={class:"flex gap-2"},Ss={key:1,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},ks={key:2,role:"alert",class:"mt-1 text-[10px]",style:{color:"var(--p-danger-500)"}},Qt=Ke({__name:"RequirementResolution",props:{requirement:{},suggestion:{}},emits:["accept","reject","edit"],setup(t){return(e,n)=>(l(),d(J,null,[t.suggestion?(l(),d("div",bs,[n[3]||(n[3]=f("span",{class:"font-semibold"},"AI",-1)),n[4]||(n[4]=F(" · Pending review: ",-1)),f("span",ws,v(N(Ce)(t.suggestion.value)),1),f("p",null,v(t.suggestion.choice_reason),1),f("div",Cs,[f("button",{type:"button",class:"ghost-sm",onClick:n[0]||(n[0]=i=>e.$emit("accept"))},"Accept suggestion"),f("button",{type:"button",class:"ghost-sm",onClick:n[1]||(n[1]=i=>e.$emit("reject"))},"Reject suggestion"),f("button",{type:"button",class:"ghost-sm",onClick:n[2]||(n[2]=i=>e.$emit("edit"))},"Edit suggestion")])])):t.requirement.choice_reason?(l(),d("p",Ss,[n[5]||(n[5]=f("span",{class:"font-semibold"},"AI",-1)),F(" · Model suggestion (accepted): "+v(t.requirement.choice_reason),1)])):y("",!0),t.requirement.resolution_error?(l(),d("p",ks,v(t.requirement.resolution_error.code)+": "+v(t.requirement.resolution_error.message)+" Choose a value manually. ",1)):y("",!0)],64))}});var Is=`
    .p-message {
        display: grid;
        grid-template-rows: 1fr;
        border-radius: dt('message.border.radius');
        outline-width: dt('message.border.width');
        outline-style: solid;
    }

    .p-message-content-wrapper {
        min-height: 0;
    }

    .p-message-content {
        display: flex;
        align-items: center;
        padding: dt('message.content.padding');
        gap: dt('message.content.gap');
    }

    .p-message-icon {
        flex-shrink: 0;
    }

    .p-message-close-button {
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        margin-inline-start: auto;
        overflow: hidden;
        position: relative;
        width: dt('message.close.button.width');
        height: dt('message.close.button.height');
        border-radius: dt('message.close.button.border.radius');
        background: transparent;
        transition:
            background dt('message.transition.duration'),
            color dt('message.transition.duration'),
            outline-color dt('message.transition.duration'),
            box-shadow dt('message.transition.duration'),
            opacity 0.3s;
        outline-color: transparent;
        color: inherit;
        padding: 0;
        border: none;
        cursor: pointer;
        user-select: none;
    }

    .p-message-close-icon {
        font-size: dt('message.close.icon.size');
        width: dt('message.close.icon.size');
        height: dt('message.close.icon.size');
    }

    .p-message-close-button:focus-visible {
        outline-width: dt('message.close.button.focus.ring.width');
        outline-style: dt('message.close.button.focus.ring.style');
        outline-offset: dt('message.close.button.focus.ring.offset');
    }

    .p-message-info {
        background: dt('message.info.background');
        outline-color: dt('message.info.border.color');
        color: dt('message.info.color');
        box-shadow: dt('message.info.shadow');
    }

    .p-message-info .p-message-close-button:focus-visible {
        outline-color: dt('message.info.close.button.focus.ring.color');
        box-shadow: dt('message.info.close.button.focus.ring.shadow');
    }

    .p-message-info .p-message-close-button:hover {
        background: dt('message.info.close.button.hover.background');
    }

    .p-message-info.p-message-outlined {
        color: dt('message.info.outlined.color');
        outline-color: dt('message.info.outlined.border.color');
    }

    .p-message-info.p-message-simple {
        color: dt('message.info.simple.color');
    }

    .p-message-success {
        background: dt('message.success.background');
        outline-color: dt('message.success.border.color');
        color: dt('message.success.color');
        box-shadow: dt('message.success.shadow');
    }

    .p-message-success .p-message-close-button:focus-visible {
        outline-color: dt('message.success.close.button.focus.ring.color');
        box-shadow: dt('message.success.close.button.focus.ring.shadow');
    }

    .p-message-success .p-message-close-button:hover {
        background: dt('message.success.close.button.hover.background');
    }

    .p-message-success.p-message-outlined {
        color: dt('message.success.outlined.color');
        outline-color: dt('message.success.outlined.border.color');
    }

    .p-message-success.p-message-simple {
        color: dt('message.success.simple.color');
    }

    .p-message-warn {
        background: dt('message.warn.background');
        outline-color: dt('message.warn.border.color');
        color: dt('message.warn.color');
        box-shadow: dt('message.warn.shadow');
    }

    .p-message-warn .p-message-close-button:focus-visible {
        outline-color: dt('message.warn.close.button.focus.ring.color');
        box-shadow: dt('message.warn.close.button.focus.ring.shadow');
    }

    .p-message-warn .p-message-close-button:hover {
        background: dt('message.warn.close.button.hover.background');
    }

    .p-message-warn.p-message-outlined {
        color: dt('message.warn.outlined.color');
        outline-color: dt('message.warn.outlined.border.color');
    }

    .p-message-warn.p-message-simple {
        color: dt('message.warn.simple.color');
    }

    .p-message-error {
        background: dt('message.error.background');
        outline-color: dt('message.error.border.color');
        color: dt('message.error.color');
        box-shadow: dt('message.error.shadow');
    }

    .p-message-error .p-message-close-button:focus-visible {
        outline-color: dt('message.error.close.button.focus.ring.color');
        box-shadow: dt('message.error.close.button.focus.ring.shadow');
    }

    .p-message-error .p-message-close-button:hover {
        background: dt('message.error.close.button.hover.background');
    }

    .p-message-error.p-message-outlined {
        color: dt('message.error.outlined.color');
        outline-color: dt('message.error.outlined.border.color');
    }

    .p-message-error.p-message-simple {
        color: dt('message.error.simple.color');
    }

    .p-message-secondary {
        background: dt('message.secondary.background');
        outline-color: dt('message.secondary.border.color');
        color: dt('message.secondary.color');
        box-shadow: dt('message.secondary.shadow');
    }

    .p-message-secondary .p-message-close-button:focus-visible {
        outline-color: dt('message.secondary.close.button.focus.ring.color');
        box-shadow: dt('message.secondary.close.button.focus.ring.shadow');
    }

    .p-message-secondary .p-message-close-button:hover {
        background: dt('message.secondary.close.button.hover.background');
    }

    .p-message-secondary.p-message-outlined {
        color: dt('message.secondary.outlined.color');
        outline-color: dt('message.secondary.outlined.border.color');
    }

    .p-message-secondary.p-message-simple {
        color: dt('message.secondary.simple.color');
    }

    .p-message-contrast {
        background: dt('message.contrast.background');
        outline-color: dt('message.contrast.border.color');
        color: dt('message.contrast.color');
        box-shadow: dt('message.contrast.shadow');
    }

    .p-message-contrast .p-message-close-button:focus-visible {
        outline-color: dt('message.contrast.close.button.focus.ring.color');
        box-shadow: dt('message.contrast.close.button.focus.ring.shadow');
    }

    .p-message-contrast .p-message-close-button:hover {
        background: dt('message.contrast.close.button.hover.background');
    }

    .p-message-contrast.p-message-outlined {
        color: dt('message.contrast.outlined.color');
        outline-color: dt('message.contrast.outlined.border.color');
    }

    .p-message-contrast.p-message-simple {
        color: dt('message.contrast.simple.color');
    }

    .p-message-text {
        font-size: dt('message.text.font.size');
        font-weight: dt('message.text.font.weight');
    }

    .p-message-icon {
        font-size: dt('message.icon.size');
        width: dt('message.icon.size');
        height: dt('message.icon.size');
    }

    .p-message-sm .p-message-content {
        padding: dt('message.content.sm.padding');
    }

    .p-message-sm .p-message-text {
        font-size: dt('message.text.sm.font.size');
    }

    .p-message-sm .p-message-icon {
        font-size: dt('message.icon.sm.size');
        width: dt('message.icon.sm.size');
        height: dt('message.icon.sm.size');
    }

    .p-message-sm .p-message-close-icon {
        font-size: dt('message.close.icon.sm.size');
        width: dt('message.close.icon.sm.size');
        height: dt('message.close.icon.sm.size');
    }

    .p-message-lg .p-message-content {
        padding: dt('message.content.lg.padding');
    }

    .p-message-lg .p-message-text {
        font-size: dt('message.text.lg.font.size');
    }

    .p-message-lg .p-message-icon {
        font-size: dt('message.icon.lg.size');
        width: dt('message.icon.lg.size');
        height: dt('message.icon.lg.size');
    }

    .p-message-lg .p-message-close-icon {
        font-size: dt('message.close.icon.lg.size');
        width: dt('message.close.icon.lg.size');
        height: dt('message.close.icon.lg.size');
    }

    .p-message-outlined {
        background: transparent;
        outline-width: dt('message.outlined.border.width');
    }

    .p-message-simple {
        background: transparent;
        outline-color: transparent;
        box-shadow: none;
    }

    .p-message-simple .p-message-content {
        padding: dt('message.simple.content.padding');
    }

    .p-message-outlined .p-message-close-button:hover,
    .p-message-simple .p-message-close-button:hover {
        background: transparent;
    }

    .p-message-enter-active {
        animation: p-animate-message-enter 0.3s ease-out forwards;
        overflow: hidden;
    }

    .p-message-leave-active {
        animation: p-animate-message-leave 0.15s ease-in forwards;
        overflow: hidden;
    }

    @keyframes p-animate-message-enter {
        from {
            opacity: 0;
            grid-template-rows: 0fr;
        }
        to {
            opacity: 1;
            grid-template-rows: 1fr;
        }
    }

    @keyframes p-animate-message-leave {
        from {
            opacity: 1;
            grid-template-rows: 1fr;
        }
        to {
            opacity: 0;
            margin: 0;
            grid-template-rows: 0fr;
        }
    }
`,Os={root:function(e){var n=e.props;return["p-message p-component p-message-"+n.severity,{"p-message-outlined":n.variant==="outlined","p-message-simple":n.variant==="simple","p-message-sm":n.size==="small","p-message-lg":n.size==="large"}]},contentWrapper:"p-message-content-wrapper",content:"p-message-content",icon:"p-message-icon",text:"p-message-text",closeButton:"p-message-close-button",closeIcon:"p-message-close-icon"},xs=he.extend({name:"message",style:Is,classes:Os}),$s={name:"BaseMessage",extends:Ne,props:{severity:{type:String,default:"info"},closable:{type:Boolean,default:!1},life:{type:Number,default:null},icon:{type:String,default:void 0},closeIcon:{type:String,default:void 0},closeButtonProps:{type:null,default:null},size:{type:String,default:null},variant:{type:String,default:null}},style:xs,provide:function(){return{$pcMessage:this,$parentInstance:this}}};function Re(t){"@babel/helpers - typeof";return Re=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},Re(t)}function qt(t,e,n){return(e=zs(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function zs(t){var e=Ls(t,"string");return Re(e)=="symbol"?e:e+""}function Ls(t,e){if(Re(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(Re(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var kn={name:"Message",extends:$s,inheritAttrs:!1,emits:["close","life-end"],timeout:null,data:function(){return{visible:!0}},mounted:function(){var e=this;this.life&&setTimeout(function(){e.visible=!1,e.$emit("life-end")},this.life)},methods:{close:function(e){this.visible=!1,this.$emit("close",e)}},computed:{closeAriaLabel:function(){return this.$primevue.config.locale.aria?this.$primevue.config.locale.aria.close:void 0},dataP:function(){return me(qt(qt({outlined:this.variant==="outlined",simple:this.variant==="simple"},this.severity,this.severity),this.size,this.size))}},directives:{ripple:vt},components:{TimesIcon:et}};function je(t){"@babel/helpers - typeof";return je=typeof Symbol=="function"&&typeof Symbol.iterator=="symbol"?function(e){return typeof e}:function(e){return e&&typeof Symbol=="function"&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e},je(t)}function en(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);e&&(i=i.filter(function(s){return Object.getOwnPropertyDescriptor(t,s).enumerable})),n.push.apply(n,i)}return n}function tn(t){for(var e=1;e<arguments.length;e++){var n=arguments[e]!=null?arguments[e]:{};e%2?en(Object(n),!0).forEach(function(i){_s(t,i,n[i])}):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):en(Object(n)).forEach(function(i){Object.defineProperty(t,i,Object.getOwnPropertyDescriptor(n,i))})}return t}function _s(t,e,n){return(e=Ps(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function Ps(t){var e=Es(t,"string");return je(e)=="symbol"?e:e+""}function Es(t,e){if(je(t)!="object"||!t)return t;var n=t[Symbol.toPrimitive];if(n!==void 0){var i=n.call(t,e);if(je(i)!="object")return i;throw new TypeError("@@toPrimitive must return a primitive value.")}return(e==="string"?String:Number)(t)}var Ms=["data-p"],As=["data-p"],Ds=["data-p"],Vs=["aria-label","data-p"],Ts=["data-p"];function Bs(t,e,n,i,s,o){var c=le("TimesIcon"),p=ht("ripple");return l(),G(gt,w({name:"p-message",appear:""},t.ptmi("transition")),{default:ne(function(){return[s.visible?(l(),d("div",w({key:0,class:t.cx("root"),role:"alert","aria-live":"assertive","aria-atomic":"true","data-p":o.dataP},t.ptm("root")),[f("div",w({class:t.cx("contentWrapper")},t.ptm("contentWrapper")),[t.$slots.container?_(t.$slots,"container",{key:0,closeCallback:o.close}):(l(),d("div",w({key:1,class:t.cx("content"),"data-p":o.dataP},t.ptm("content")),[_(t.$slots,"icon",{class:ee(t.cx("icon"))},function(){return[(l(),G(Ie(t.icon?"span":null),w({class:[t.cx("icon"),t.icon],"data-p":o.dataP},t.ptm("icon")),null,16,["class","data-p"]))]}),t.$slots.default?(l(),d("div",w({key:0,class:t.cx("text"),"data-p":o.dataP},t.ptm("text")),[_(t.$slots,"default")],16,Ds)):y("",!0),t.closable?Se((l(),d("button",w({key:1,class:t.cx("closeButton"),"aria-label":o.closeAriaLabel,type:"button",onClick:e[0]||(e[0]=function(m){return o.close(m)}),"data-p":o.dataP},tn(tn({},t.closeButtonProps),t.ptm("closeButton"))),[_(t.$slots,"closeicon",{},function(){return[t.closeIcon?(l(),d("i",w({key:0,class:[t.cx("closeIcon"),t.closeIcon],"data-p":o.dataP},t.ptm("closeIcon")),null,16,Ts)):(l(),G(c,w({key:1,class:[t.cx("closeIcon"),t.closeIcon],"data-p":o.dataP},t.ptm("closeIcon")),null,16,["class","data-p"]))]})],16,Vs)),[[p]]):y("",!0)],16,As))],16)],16,Ms)):y("",!0)]}),_:3},16)}kn.render=Bs;const Fs={key:0},Rs={key:1},js={class:"whitespace-pre-wrap break-words text-[11px]"},qe=Ke({__name:"HubRequestError",props:{error:{}},setup(t){const e=t,n=Y(()=>typeof e.error=="string"?{message:e.error}:e.error);return(i,s)=>(l(),G(N(kn),{severity:"error",closable:!1,class:"mt-2"},{default:ne(()=>[n.value.code?(l(),d("span",Fs,v(n.value.code)+": ",1)):y("",!0),F(v(n.value.message)+" ",1),_(i.$slots,"default"),n.value.details!=null?(l(),d("details",Rs,[s[0]||(s[0]=f("summary",null,"Error details",-1)),f("pre",js,v(JSON.stringify(n.value.details,null,2)),1)])):y("",!0)]),_:3}))}}),Ks={class:"dialog-body"},Hs=["for"],Ns=["id"],Us=["for"],Ws=["id"],Gs={class:"field-hint"},Zs={key:0,class:"mono"},Ys={class:"mt-3 flex items-center justify-between gap-2 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Xs={key:0},Js={key:1},Qs={class:"text-success-500"},qs={class:"text-warn-500"},ea={key:2},ta={class:"flex items-center gap-2"},na=["disabled"],ia=["disabled"],oa={key:1,role:"status",class:"field-hint"},sa={key:2,class:"tree"},aa={class:"tree-indent"},ra={key:0,class:"tree-branch"},la=["title"],ua={class:"tree-ver mono"},da={key:0,class:"tree-role"},ca=["title"],pa={key:3,class:"legend"},fa={key:4,class:"mt-3 mb-3"},ma={class:"form-label flex items-center gap-1.5"},ha={class:"dim"},ga={class:"space-y-2"},va={class:"flex items-center gap-2 mb-1"},ya={class:"mono text-[11px]",style:{color:"var(--p-text-color)"}},ba={key:0,class:"text-[9px]",style:{color:"var(--p-warn-500)"}},wa={key:1,class:"text-[9px]",style:{color:"var(--p-danger-500)"}},Ca={key:2,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},Sa={key:3,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},ka={key:4,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},Ia={key:0,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Oa={class:"mono"},xa={key:1,class:"mt-1 text-[10px]",style:{color:"var(--p-danger-500)"}},$a={key:2,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},za={key:3,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},La={key:5,class:"mt-3 mb-3"},_a={class:"form-label flex items-center gap-1.5"},Pa={class:"dim"},Ea={class:"space-y-2"},Ma={class:"flex items-center gap-2 mb-1"},Aa={class:"mono text-[11px]",style:{color:"var(--p-text-color)"}},Da={key:0,class:"text-[9px]",style:{color:"var(--p-danger-500)"}},Va={key:1,class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},Ta={key:0,class:"mt-1 text-[10px]",style:{color:"var(--p-danger-500)"}},Ba={key:1,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},Fa={class:"mono"},Ra={key:2,class:"mt-1 text-[10px]",style:{color:"var(--p-text-muted-color)"}},ja={key:6,class:"mt-3 mb-3 text-[11px]",style:{color:"var(--p-text-muted-color)"}},Ka={class:"form-check"},Ha={class:"scan-panel"},Na={class:"scan-head"},Ua={class:"scan-title"},Wa={key:0,class:"scan-state"},Ga={key:1,class:"scan-summary"},Za={class:"scan-summary-line"},Ya={class:"mono dim"},Xa={key:0,class:"scan-modules"},Ja={class:"mono scan-module-name"},Qa={class:"mono dim"},qa={key:1,class:"scan-findings"},er={class:"scan-finding-title"},tr={class:"mono dim"},nr={key:0,class:"mono scan-finding-location"},ir={key:1,class:"scan-finding-detail"},or={key:2,class:"scan-state skipped"},sr={key:3,class:"scan-state"},ar={class:"scan-actions"},rr=["disabled"],lr=["disabled"],ur={key:7,class:"mt-2 px-2 py-1.5 rounded text-[11px] bg-danger-500/15 text-danger-500"},dr={class:"flex justify-end gap-2 mt-4"},cr=["disabled"],pr=["disabled"],fr=Ke({__name:"HubInstallDialog",props:{modelValue:{type:Boolean},component:{},initialVersion:{}},emits:["update:modelValue","installed"],setup(t,{emit:e}){const n=t,i=e,s=dn(),o=Vt(),c=Vt(),p=W(""),m=W(""),g=W(!1),h=W(!0),b=W(!1),S=W(null),C=W(!1),O=W(null),L=W(null),P=W(!1);let M=0;const A=we(null),j=W(!1),x=W(!1),R=W(null),z=we([]),k=we({}),D=we({}),H=we({}),Q=we({}),$=W({}),Z=W(!1),oe=W(null);let q=0;function U(){q+=1,Z.value=!1,j.value=!1,x.value=!1,H.value={},oe.value=null,Et()}const se=W({});on(()=>n.modelValue,r=>{r?ge():U()});function ge(){U(),Q.value={},$.value={},p.value=n.initialVersion||"",m.value="",g.value=!1,h.value=!0,b.value=!1,S.value=null,Et(),A.value=null,R.value=null,z.value=[],k.value={},D.value={},x.value=!1,xn(),de()}function xe(){b.value||(U(),i("update:modelValue",!1))}function V(r){return(r.parameter_name||r.full_id||r.name||"").trim()}const $e=Y(()=>{const r=new Set;for(const u of A.value?.graph||[])(u.depth??0)===0&&r.add(u.module);return r});function ve(r){return r.module&&$e.value.size?$e.value.has(r.module):r.transitive!==void 0?!r.transitive:(r.depth??0)===0}const ye=Y(()=>z.value.filter(ve)),Ue=Y(()=>z.value.filter(r=>!ve(r)));function We(r){return ue(D.value[V(r)])?r.missing||r.invalid?!0:!!r.required&&ue(r.value):!!r.invalid}const be=Y(()=>Ue.value.filter(We));function tt(r){return D.value[V(r)]??r.value??""}function wt(r,u){U();const a=V(r);D.value={...D.value,[a]:u},St(a)}function Ct(r,u){const a=V(r);a&&(k.value[a]!==u&&U(),k.value={...k.value,[a]:u},St(a))}function St(r){const u={...Q.value};delete u[r],Q.value=u}function kt(r,u){$.value[V(r)]=u,u||U()}function It(r){return r.expected_type?`Enter ${r.expected_type}${r.expected_type==="string"?"":" as JSON"}`:r.expected_kind?`Enter ${r.expected_kind} id or contract value`:"Enter registry id or contract value"}function Ot(){return g.value&&m.value.trim()||void 0}function In(){g.value=!0,U()}const xt=Y(()=>A.value?.dependency?.id||"");function $t(r,u=k.value){A.value=r,Z.value=!0,z.value=r.requirements||[];const a=new Set(z.value.map(V));$.value=Object.fromEntries(Object.entries($.value).filter(([B])=>a.has(B)));const I={};for(const B of ye.value){const te=V(B);te&&(I[te]=B.value??u[te]??"")}k.value=I,D.value=Object.fromEntries((r.install_payload.requirement_bindings||[]).map(B=>[B.name,B.value]))}const zt=Y(()=>z.value.filter(r=>{const u=ve(r)?k.value[V(r)]:tt(r);return ue(u)&&(r.missing||r.value_source==="conflict"||r.suggestions?.length||r.expected_type)}).map(r=>r.full_id||V(r))),Ge=Y(()=>Object.keys(H.value).length);async function On(){const r=[...zt.value];if(!Z.value||!r.length)return;x.value=!0,oe.value=null;const u=q;try{const a=await di(s,{...it(),requirement_ids:r});if(u!==q)return;const I=new Set(r),B={},te=new Map(a.requirements.map(E=>[E.full_id||V(E),E]));z.value=z.value.map(E=>{const T=E.full_id||V(E),X=te.get(T);return!I.has(T)||!X?E:(X.value_source==="llm"&&!X.invalid&&!ue(X.value)&&(B[V(E)]=X),{...E,resolution_error:X.resolution_error})}),H.value=B,!Object.keys(B).length&&!a.requirements.some(E=>E.resolution_error)&&(oe.value="No valid AI suggestion is available. Choose a value manually.")}catch(a){u===q&&(oe.value=Ee(a))}finally{u===q&&(x.value=!1)}}async function nt(r){const u=r.map(T=>H.value[T]).filter(Boolean);if(!u.length)return;const a={...Q.value},I={...H.value};for(const T of r)delete I[T];for(const T of u){const X=V(T);T.value!==void 0&&(ve(T)?k.value={...k.value,[X]:T.value}:D.value={...D.value,[X]:T.value},a[X]=T)}U(),Q.value=a;const B=de(),te=q;if(await B,te!==q||!Z.value)return;const E={};for(const T of z.value){const X=V(T),ce=I[X];if(!ce||T.expected_type!==ce.expected_type||T.expected_kind!==ce.expected_kind)continue;const Je=ve(T)?k.value[X]:tt(T);ue(Je)&&(T.expected_kind&&!T.suggestions?.some(at=>at.value===ce.value)||(E[X]=ce))}H.value=E}function Lt(r){const u={...H.value};delete u[V(r)],H.value=u}function _t(r){const u=H.value[V(r)];u?.value!==void 0&&(ve(r)?Ct(r,u.value):wt(r,u.value))}function Pt(r){return Q.value[V(r)]||r}async function de(){if(!n.component.trim())return;U();const r=q;j.value=!0,R.value=null;const u={...k.value},a=Object.entries(u).filter(([,I])=>!ue(I)).map(([I,B])=>({name:I,value:B}));try{const I=await ui(s,{component:n.component.trim(),version:p.value.trim()||void 0,namespace:Ot(),run_migrations:h.value,migration_policy:h.value?"up":"none",parameters:a.length?a:void 0,requirement_bindings:Object.entries(D.value).map(([B,te])=>({name:B,value:te}))});if(r!==q)return;$t(I,u)}catch(I){if(r!==q)return;A.value=null,Z.value=!1,R.value=Ee(I)}finally{r===q&&(j.value=!1)}}async function xn(){try{const r=await ai(s,{entries:!1,migrations:!1}),u={};for(const a of r.modules||[])a.name&&a.version&&(u[a.name]=a.version);for(const a of r.dependencies||[]){const I=a.component||a.name,B=a.installed_version||a.version;I&&B&&!u[I]&&(u[I]=B)}se.value=u}catch(r){S.value=Ee(r),se.value={}}}function $n(){const r=[];for(const u of ye.value){const a=V(u);if(!a)continue;const I=k.value[a];!ue(I)&&!u.invalid&&I!==void 0&&r.push({name:a,value:I})}return r.length?r:void 0}function it(){return{component:n.component.trim(),version:p.value.trim()||void 0,namespace:Ot(),run_migrations:h.value,migration_policy:h.value?"up":"none",parameters:$n(),requirement_bindings:Object.entries(D.value).map(([r,u])=>({name:r,value:u}))}}const Ze=Y(()=>{const r=[];for(const u of ye.value){const a=V(u);!a||!u.required&&!u.missing||(u.invalid||ue(k.value[a]))&&r.push(a)}return r});function Et(){M+=1,C.value=!1,O.value=null,L.value=null,P.value=!1}async function zn(){if(!n.component.trim()){O.value="Component required";return}C.value=!0,O.value=null,L.value=null,P.value=!1;const r=M+1;M=r;try{const u=await ci(s,it());r===M&&(L.value=u)}catch(u){if(r!==M)return;O.value=Ee(u)}finally{r===M&&(C.value=!1)}}function Ln(){M+=1,C.value=!1,O.value=null,L.value=null,P.value=!0}const _n=Y(()=>P.value||!!L.value),Mt=Y(()=>!A.value||!Z.value||A.value.applicable===!1||Ge.value>0||Object.values($.value).includes(!1)||b.value||j.value||x.value||C.value||!_n.value||Ze.value.length>0||be.value.length>0);function At(r){return(r||"pending").toString().toUpperCase()}function ot(r){const u=(r||"").toString().toLowerCase();return u==="clean"?"clean":u==="critical"?"critical":u==="warnings"||u==="warning"?"warnings":u==="error"?"error":"pending"}function Pn(r){return ot(r.severity)}const st=Y(()=>L.value?.modules||[]),Dt=Y(()=>{const r=[];for(const u of st.value)for(const a of u.findings||[])r.push({...a,module_name:u.module});return r});async function En(){if(Mt.value){S.value="Review a valid current plan and confirm requirement suggestions before installing";return}if(!n.component.trim()){S.value="Component required";return}if(Ze.value.length){const r=Ze.value.length;S.value=`Configure required parameter${r===1?"":"s"}: ${Ze.value.join(", ")}`;return}if(be.value.length){const r=be.value[0];S.value=`Configure dependency requirement ${V(r)} of ${r.module} before installing`;return}b.value=!0,S.value=null;try{const r=await li(s,it());b.value=!1,i("installed",n.component.trim(),ri(r)),xe()}catch(r){const u=r.response?.data;if(u?.code==="PARAMETER_TARGET_TRANSITIVE")S.value=u.error||u.message||"Parameter targets a transitive module; install that module directly with this parameter";else{const a=u?.details;a?.requirements&&a?.install_payload&&$t(a),S.value=Ee(r)}}finally{b.value=!1}}const Ye=Y(()=>{const r=A.value?.graph||[];if(!r.length)return[];const u=new Map,a=[];for(const E of r)if(!E.parent||(E.depth??0)===0)a.push(E);else{const T=u.get(E.parent)||[];T.push(E),u.set(E.parent,T)}const I=[],B=new Set,te=(E,T,X,ce)=>{if(B.has(E.module))return;B.add(E.module),I.push({node:E,depth:T,last:X,guides:ce});const Je=u.get(E.module)||[];Je.forEach((at,Mn)=>{te(at,T+1,Mn===Je.length-1,[...ce,!X])})};a.forEach((E,T)=>te(E,0,T===a.length-1,[]));for(const E of r)B.has(E.module)||I.push({node:E,depth:E.depth??0,last:!0,guides:[]});return I});function Xe(r){if(!r.installed)return{kind:"new",label:"NEW",title:"Not installed yet — will be added"};const u=se.value[r.module],a=r.version;return u&&a&&u!==a?{kind:"upgrade",label:`UPGRADE ${u} → ${a}`,title:"Installed at a different version — this install changes it"}:r.shared?{kind:"shared",label:"SHARED",title:"Already installed and reused — reached from another installed module"}:{kind:"installed",label:"INSTALLED",title:"Already installed at this version"}}const pe=Y(()=>{const r=Ye.value;let u=0,a=0,I=0;for(const B of r){const te=Xe(B.node).kind;te==="new"?u++:te==="upgrade"?I++:a++}return{added:u,reused:a,upgraded:I,total:r.length}});return(r,u)=>(l(),G(nn,{to:"body"},[K(N(hn),{visible:t.modelValue,modal:"",draggable:!1,closable:!b.value,"close-on-escape":!b.value,header:`Install ${t.component}`,class:"keeper-install-dialog",style:{width:"600px",maxWidth:"95vw"},"onUpdate:visible":xe},{default:ne(()=>[f("div",Ks,[u[20]||(u[20]=f("p",{class:"text-[11px] mb-3 leading-relaxed",style:{color:"var(--p-text-muted-color)"}}," Installs a component from the hub and applies its registry entries. The plan below resolves the full dependency tree before anything changes. ",-1)),f("label",{for:N(o),class:"form-label"},"Version",8,Hs),Se(f("input",{id:N(o),"onUpdate:modelValue":u[0]||(u[0]=a=>p.value=a),placeholder:"latest",class:"form-input mono",onInput:U,onChange:de},null,40,Ns),[[Tt,p.value]]),f("label",{for:N(c),class:"form-label mt-3"},"Dependency namespace",8,Us),Se(f("input",{id:N(c),"onUpdate:modelValue":u[1]||(u[1]=a=>m.value=a),placeholder:"auto",class:"form-input mono",onInput:In,onChange:de},null,40,Ws),[[Tt,m.value]]),f("div",Gs,[u[4]||(u[4]=F(" Auto target uses an existing dependency entry or the strongest dependency namespace cluster. ",-1)),xt.value?(l(),d("span",Zs,v(xt.value),1)):y("",!0)]),f("div",Ys,[j.value?(l(),d("span",Xs,"Resolving install plan…")):A.value?(l(),d("span",Js,[F(v(pe.value.total)+" module"+v(pe.value.total===1?"":"s")+" · ",1),f("span",Qs,v(pe.value.added)+" new",1),pe.value.upgraded?(l(),d(J,{key:0},[u[5]||(u[5]=F(" · ",-1)),f("span",qs,v(pe.value.upgraded)+" upgrade",1)],64)):y("",!0),pe.value.reused?(l(),d(J,{key:1},[F(" · "+v(pe.value.reused)+" reused",1)],64)):y("",!0)])):(l(),d("span",ea,"Plan resolves transitive dependencies before install.")),f("div",ta,[zt.value.length?(l(),d("button",{key:0,class:"ghost-sm",type:"button",onClick:On,disabled:!Z.value||j.value||x.value||b.value},v(x.value?"Suggesting…":"Suggest with AI"),9,na)):y("",!0),f("button",{class:"ghost-sm",type:"button",onClick:de,disabled:j.value||x.value},"Refresh",8,ia)])]),oe.value?(l(),G(qe,{key:0,error:oe.value},{default:ne(()=>[...u[6]||(u[6]=[F(" You can enter values manually.",-1)])]),_:1},8,["error"])):y("",!0),Ge.value?(l(),d("div",oa,[F(" Review "+v(Ge.value)+" AI suggestion"+v(Ge.value===1?"":"s")+" before applying. ",1),f("button",{type:"button",class:"ghost-sm",onClick:u[2]||(u[2]=a=>nt(Object.keys(H.value)))},"Accept all")])):y("",!0),Ye.value.length?(l(),d("div",sa,[(l(!0),d(J,null,re(Ye.value,a=>(l(),d("div",{key:a.node.path||a.node.module,class:"tree-row"},[f("span",aa,[(l(!0),d(J,null,re(a.guides,(I,B)=>(l(),d("span",{key:B,class:ee(["tree-guide",{on:I}])},null,2))),128)),a.depth>0?(l(),d("span",ra,v(a.last?"└":"├"),1)):y("",!0)]),f("span",{class:ee(["tree-name mono",{direct:a.node.direct}]),title:a.node.module},v(a.node.module),11,la),f("span",ua,v(a.node.version||a.node.constraint||""),1),a.node.direct?(l(),d("span",da,"direct")):y("",!0),f("span",{class:ee(["node-badge",Xe(a.node).kind]),title:Xe(a.node).title},v(Xe(a.node).label),11,ca)]))),128))])):y("",!0),Ye.value.length?(l(),d("div",pa,[...u[7]||(u[7]=[f("span",{class:"node-badge new"},"NEW",-1),f("span",{class:"legend-txt"},"added by this install",-1),f("span",{class:"node-badge upgrade"},"UPGRADE",-1),f("span",{class:"legend-txt"},"installed version changes",-1),f("span",{class:"node-badge shared"},"SHARED",-1),f("span",{class:"legend-txt"},"already installed, reused",-1),f("span",{class:"node-badge installed"},"INSTALLED",-1),f("span",{class:"legend-txt"},"present, unchanged",-1)])])):y("",!0),ye.value.length?(l(),d("div",fa,[f("div",ma,[K(N(ae),{icon:"tabler:list-check",class:"w-3.5 h-3.5"}),u[8]||(u[8]=F(" Configuration ",-1)),f("span",ha,"("+v(ye.value.length)+")",1)]),f("div",ga,[(l(!0),d(J,null,re(ye.value,a=>(l(),d("label",{key:a.parameter_name||a.name,class:"block"},[f("div",va,[f("span",ya,v(a.parameter_name||a.name),1),a.required?(l(),d("span",ba,"required")):y("",!0),a.invalid?(l(),d("span",wa,"invalid")):y("",!0),a.value_source&&a.value_source!=="empty"?(l(),d("span",Ca,v(a.value_source),1)):y("",!0),a.expected_kind?(l(),d("span",Sa,v(a.expected_kind),1)):y("",!0),a.targets?.length?(l(),d("span",ka,v(a.targets.length)+" target"+v(a.targets.length===1?"":"s"),1)):y("",!0)]),K(Jt,{"model-value":k.value[V(a)]??"",requirement:a,placeholder:It(a),"onUpdate:modelValue":I=>Ct(a,I),onCommit:de,onValidity:I=>kt(a,I)},null,8,["model-value","requirement","placeholder","onUpdate:modelValue","onValidity"]),!N(ue)(a.default)&&a.value_source!=="default"?(l(),d("div",Ia,[u[9]||(u[9]=F("Package default: ",-1)),f("span",Oa,v(N(Ce)(a.default)),1)])):y("",!0),a.invalid_reason?(l(),d("div",xa,v(a.invalid_reason),1)):y("",!0),K(Qt,{requirement:Pt(a),suggestion:H.value[V(a)],onAccept:I=>nt([V(a)]),onReject:I=>Lt(a),onEdit:I=>_t(a)},null,8,["requirement","suggestion","onAccept","onReject","onEdit"]),a.module?(l(),d("div",$a,v(a.module)+v(a.version?"@"+a.version:""),1)):y("",!0),a.description?(l(),d("div",za,v(a.description),1)):y("",!0)]))),128))])])):y("",!0),Ue.value.length?(l(),d("div",La,[f("div",_a,[K(N(ae),{icon:"tabler:sitemap",class:"w-3.5 h-3.5"}),u[10]||(u[10]=F(" Dependency configuration ",-1)),f("span",Pa,"("+v(Ue.value.length)+")",1)]),f("div",Ea,[(l(!0),d(J,null,re(Ue.value,a=>(l(),d("div",{key:a.parameter_name||a.name,class:ee(["transitive-req",{blocked:We(a)}])},[f("div",Ma,[f("span",Aa,v(a.parameter_name||a.name),1),u[11]||(u[11]=f("span",{class:"text-[9px]",style:{color:"var(--p-text-muted-color)"}},"transitive",-1)),We(a)?(l(),d("span",Da,"unsatisfied")):a.value_source&&a.value_source!=="empty"?(l(),d("span",Va,v(a.value_source),1)):y("",!0)]),K(Jt,{"model-value":tt(a),requirement:a,disabled:b.value||j.value||x.value,placeholder:It(a),"onUpdate:modelValue":I=>wt(a,I),onCommit:de,onValidity:I=>kt(a,I)},null,8,["model-value","requirement","disabled","placeholder","onUpdate:modelValue","onValidity"]),K(Qt,{requirement:Pt(a),suggestion:H.value[V(a)],onAccept:I=>nt([V(a)]),onReject:I=>Lt(a),onEdit:I=>_t(a)},null,8,["requirement","suggestion","onAccept","onReject","onEdit"]),We(a)?(l(),d("div",Ta,v(a.invalid_reason||"No value satisfies this requirement."),1)):(l(),d("div",Ba,[u[12]||(u[12]=F(" Applies to ",-1)),f("span",Fa,v(a.module),1),u[13]||(u[13]=F(" through its dependency binding. ",-1))])),a.description?(l(),d("div",Ra,v(a.description),1)):y("",!0)],2))),128))])])):y("",!0),A.value&&!j.value&&!z.value.length?(l(),d("div",ja," No configuration required. ")):y("",!0),f("label",Ka,[Se(f("input",{"onUpdate:modelValue":u[3]||(u[3]=a=>h.value=a),type:"checkbox",onChange:de},null,544),[[Bn,h.value]]),u[14]||(u[14]=F(" Run migrations after install ",-1))]),f("section",Ha,[f("div",Na,[f("div",Ua,[K(N(ae),{icon:"tabler:shield-check",class:"w-3.5 h-3.5"}),u[15]||(u[15]=F(" Security review ",-1))]),f("span",{class:ee(["scan-badge",P.value?"skipped":ot(L.value?.overall_status)])},v(P.value?"SKIPPED":L.value?At(L.value.overall_status):C.value?"RUNNING":"PENDING"),3)]),C.value?(l(),d("div",Wa,[K(N(ae),{icon:"tabler:loader-2",class:"w-3.5 h-3.5 animate-spin"}),F(" Reviewing "+v(t.component)+" before install ",1)])):L.value?(l(),d("div",Ga,[f("div",Za,[F(v(L.value.overall_summary)+" ",1),f("span",Ya,v(L.value.scanned)+"/"+v(L.value.total),1)]),st.value.length?(l(),d("div",Xa,[(l(!0),d(J,null,re(st.value,a=>(l(),d("div",{key:a.module,class:"scan-module"},[f("span",Ja,v(a.module),1),f("span",Qa,v(a.version||""),1),f("span",{class:ee(["scan-mini-badge",ot(a.status)])},v(At(a.status)),3)]))),128))])):y("",!0),Dt.value.length?(l(),d("div",qa,[(l(!0),d(J,null,re(Dt.value,(a,I)=>(l(),d("div",{key:I,class:ee(["scan-finding",Pn(a)])},[f("div",er,[f("span",null,v(a.title),1),f("span",tr,v(a.module_name),1)]),a.location?(l(),d("div",nr,v(a.location),1)):y("",!0),a.detail?(l(),d("div",ir,v(a.detail),1)):y("",!0)],2))),128))])):y("",!0)])):P.value?(l(),d("div",or,[K(N(ae),{icon:"tabler:shield-off",class:"w-3.5 h-3.5"}),u[16]||(u[16]=F(" Install will continue without a security review. ",-1))])):(l(),d("div",sr,[K(N(ae),{icon:"tabler:shield-question",class:"w-3.5 h-3.5"}),u[17]||(u[17]=F(" Choose a security review path before installing. ",-1))])),O.value?(l(),G(qe,{key:4,error:O.value},null,8,["error"])):y("",!0),f("div",ar,[f("button",{class:"scan-btn primary",type:"button",onClick:zn,disabled:C.value||b.value||j.value},[K(N(ae),{icon:C.value?"tabler:loader-2":"tabler:shield-search",class:ee(["w-3.5 h-3.5",{"animate-spin":C.value}])},null,8,["icon","class"]),F(" "+v(L.value?"Run again":"Run scan"),1)],8,rr),f("button",{class:"scan-btn secondary",type:"button",onClick:Ln,disabled:C.value||b.value},[K(N(ae),{icon:"tabler:player-skip-forward",class:"w-3.5 h-3.5"}),u[18]||(u[18]=F(" Skip ",-1))],8,lr)])]),be.value.length?(l(),d("div",ur,v(be.value.length)+" dependency requirement"+v(be.value.length===1?" is":"s are")+" unsatisfied. Choose a compatible value before installing. ",1)):y("",!0),R.value?(l(),G(qe,{key:8,error:R.value},null,8,["error"])):y("",!0),S.value?(l(),G(qe,{key:9,error:S.value},null,8,["error"])):y("",!0),f("div",dr,[f("button",{class:"dialog-btn cancel",onClick:xe,disabled:b.value},"Cancel",8,cr),f("button",{class:"dialog-btn proceed",onClick:En,disabled:Mt.value},[b.value?(l(),G(N(ae),{key:0,icon:"tabler:loader-2",class:"w-3 h-3 animate-spin"})):y("",!0),u[19]||(u[19]=F(" Install ",-1))],8,pr)])])]),_:1},8,["visible","closable","close-on-escape","header"])]))}}),_r=cn(fr,[["__scopeId","data-v-02692971"]]),mr={class:"install-warnings mx-4 mt-2 px-3 py-2 rounded text-[11px] flex items-start gap-2 bg-warn-500/15",role:"alert",style:{color:"var(--p-text-color)"}},hr={class:"flex-1"},gr={class:"mt-1 list-disc pl-4"},vr={key:0,class:"font-mono"},Pr=Ke({__name:"HubInstallWarnings",props:{component:{},warnings:{}},emits:["dismiss"],setup(t,{emit:e}){const n=e;return(i,s)=>(l(),d("div",mr,[K(N(ae),{icon:"tabler:alert-triangle",class:"w-3.5 h-3.5 shrink-0 mt-px"}),f("div",hr,[f("div",null,"Installed "+v(t.component)+", but a post-install step failed. Permissions or other derived state may be out of date.",1),f("ul",gr,[(l(!0),d(J,null,re(t.warnings,(o,c)=>(l(),d("li",{key:c},[o.observer?(l(),d("span",vr,v(o.observer)+": ",1)):y("",!0),F(v(o.message),1)]))),128))])]),f("button",{"aria-label":"Dismiss",onClick:s[0]||(s[0]=o=>n("dismiss")),style:{color:"var(--p-text-muted-color)"}},[K(N(ae),{icon:"tabler:x",class:"w-3 h-3"})])]))}});export{_r as H,Pr as _,kr as a,$r as b,zr as c,Lr as d,xr as g,Or as h,ai as l,Sr as p,Ir as r,Cr as u};
