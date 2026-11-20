/* SpriteKit-lite: Szenengraph, Aktionen, Texturen (y nach oben, wie SpriteKit) */
window.SK=(()=>{
'use strict';
const PI=Math.PI;
const rgba=(r,g,b,a)=>`rgba(${Math.round(r*255)},${Math.round(g*255)},${Math.round(b*255)},${a==null?1:a})`;
const white=(w,a)=>rgba(w,w,w,a);
const Theme={orange:rgba(1,.54,0),dark:rgba(.05,.05,.09),panel:rgba(.11,.11,.17),blue:rgba(.25,.8,1),green:rgba(.25,1,.45),pink:rgba(1,.3,.7),cream:rgba(1,.95,.85)};
Theme.seat=[Theme.orange,Theme.blue,Theme.green,Theme.pink];
const FONT='"Avenir Next","Avenir",Figtree,"Nunito Sans",system-ui,sans-serif';
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const rnd=(a,b)=>a+Math.random()*(b-a);
const ease={in:t=>t*t,out:t=>1-(1-t)*(1-t),inout:t=>t<.5?2*t*t:1-2*(1-t)*(1-t)};
/* seeded random wie in der App */
class Rand{constructor(seed){this.s=(seed>>>0)||1}
 next(){let t=(this.s+=0x6D2B79F5);t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}
 double(){return this.next()}range(a,b){return a+this.next()*(b-a)}int(a,b){return a+Math.floor(this.next()*(b-a+1))}chance(p){return this.next()<p}
 pick(a){return a[this.int(0,a.length-1)]}shuffled(a){a=a.slice();for(let i=a.length-1;i>0;i--){const j=this.int(0,i);[a[i],a[j]]=[a[j],a[i]]}return a}}

/* ---------- Texturen ---------- */
class Texture{constructor(cv,w,h){this.cv=cv;this.w=w;this.h=h;this.tc={}}
 tinted(col){let t=this.tc[col];if(t)return t;const k=document.createElement('canvas');k.width=this.cv.width;k.height=this.cv.height;const x=k.getContext('2d');x.drawImage(this.cv,0,0);x.globalCompositeOperation='source-in';x.fillStyle=col;x.fillRect(0,0,k.width,k.height);return this.tc[col]=k}}
const TC={};
const Gfx={};
Gfx.texture=(key,w,h,scale,draw)=>{if(TC[key])return TC[key];scale=scale||2;const cv=document.createElement('canvas');cv.width=Math.max(1,Math.ceil(w*scale));cv.height=Math.max(1,Math.ceil(h*scale));const c=cv.getContext('2d');c.scale(scale,scale);draw(c,w,h);return TC[key]=new Texture(cv,w,h)};
Gfx.image=(url)=>{const t=new Texture(document.createElement('canvas'),1,1),im=new Image();im.onload=()=>{t.cv.width=im.naturalWidth;t.cv.height=im.naturalHeight;t.cv.getContext('2d').drawImage(im,0,0);t.w=im.naturalWidth;t.h=im.naturalHeight;t.tc={}};im.src=url;return t};
const grad=(c,top,bot,w,h)=>{const g=c.createLinearGradient(0,0,0,h);g.addColorStop(0,top);g.addColorStop(1,bot);c.fillStyle=g;c.fillRect(0,0,w,h)};
Gfx.gradientColors=(c,top,bot,w,h)=>grad(c,top,bot,w,h);
Gfx.dot=()=>Gfx.texture('dot',16,16,2,c=>{c.fillStyle='#fff';c.beginPath();c.arc(8,8,8,0,7);c.fill()});
Gfx.glow=()=>Gfx.texture('glow',128,128,1,c=>{const g=c.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,'rgba(255,255,255,.9)');g.addColorStop(1,'rgba(255,255,255,0)');c.fillStyle=g;c.fillRect(0,0,128,128)});
Gfx.shadow=()=>Gfx.texture('shadow',64,24,2,c=>{c.save();c.translate(32,12);c.scale(1,.375);const g=c.createRadialGradient(0,0,0,0,0,32);g.addColorStop(0,'rgba(0,0,0,.5)');g.addColorStop(1,'rgba(0,0,0,0)');c.fillStyle=g;c.fillRect(-32,-32,64,64);c.restore()});
Gfx.ball=(r)=>Gfx.texture('ball'+Math.round(r),r*2,r*2,3,c=>{const d=r*2;c.fillStyle='#fff';c.beginPath();c.arc(r,r,r-.5,0,7);c.fill();c.strokeStyle=white(.55);c.lineWidth=Math.max(1,r*.12);c.beginPath();c.arc(r,r,r-.8,0,7);c.stroke();c.fillStyle=white(.45);const hr=r*.16;for(let i=0;i<8;i++){const a=i*PI/4;c.beginPath();c.arc(r+Math.cos(a)*r*.58,r+Math.sin(a)*r*.58,hr,0,7);c.fill()}c.beginPath();c.arc(r,r,hr,0,7);c.fill()});
const rr=(c,x,y,w,h,r)=>{r=Math.min(r,w/2,h/2);c.beginPath();c.moveTo(x+r,y);c.arcTo(x+w,y,x+w,y+h,r);c.arcTo(x+w,y+h,x,y+h,r);c.arcTo(x,y+h,x,y,r);c.arcTo(x,y,x+w,y,r);c.closePath()};
Gfx.rr=rr;
Gfx.rect=(w,h,col,corner)=>Gfx.texture('rect'+Math.round(w)+'x'+Math.round(h)+col+(corner||0),w,h,2,c=>{c.fillStyle=col;rr(c,0,0,w,h,corner||0);c.fill()});
Gfx.circle=(r,col,ring)=>Gfx.texture('circle'+Math.round(r)+col+(ring||''),r*2,r*2,2,c=>{const d=r*2;c.fillStyle=col;c.beginPath();c.arc(r,r,r-1,0,7);c.fill();if(ring){c.strokeStyle=ring;c.lineWidth=Math.max(2,r*.14);c.beginPath();c.arc(r,r,r-2,0,7);c.stroke()}});
Gfx.gradient=(key,top,bot,w,h)=>Gfx.texture('grad_'+key,w,h,1,c=>grad(c,top,bot,w,h));
Gfx.pill=(w,h,fill,border,corner,gloss)=>{corner=corner==null?16:corner;gloss=gloss!==false;return Gfx.texture('pill'+Math.round(w)+'x'+Math.round(h)+fill+(border||'')+corner+gloss,w,h,2,c=>{rr(c,1.5,1.5,w-3,h-3,corner);c.fillStyle=fill;c.fill();if(gloss){c.save();rr(c,1.5,1.5,w-3,h-3,corner);c.clip();c.fillStyle='rgba(255,255,255,.14)';c.fillRect(0,0,w,h*.45);c.restore()}if(border){rr(c,1.5,1.5,w-3,h-3,corner);c.strokeStyle=border;c.lineWidth=3;c.stroke()}})};
Gfx.star=(r,col)=>Gfx.texture('star'+Math.round(r)+col,r*2,r*2,2,c=>{c.fillStyle=col;c.beginPath();for(let i=0;i<10;i++){const rad=i%2===0?r:r*.45,a=i*PI/5-PI/2,x=r+Math.cos(a)*rad,y=r+Math.sin(a)*rad;i?c.lineTo(x,y):c.moveTo(x,y)}c.closePath();c.fill()});
Gfx.goal=(w,h)=>Gfx.texture('goal'+Math.round(w)+'x'+Math.round(h),w+16,h+12,2,c=>{const ix=8,iy=8;c.fillStyle='rgba(0,0,0,.45)';c.fillRect(ix,iy,w,h);c.strokeStyle='rgba(255,255,255,.35)';c.lineWidth=1;c.beginPath();for(let x=ix;x<=ix+w;x+=10){c.moveTo(x,iy);c.lineTo(x,iy+h)}for(let y=iy;y<=iy+h;y+=10){c.moveTo(ix,y);c.lineTo(ix+w,y)}c.stroke();c.strokeStyle=rgba(.92,.15,.12);c.lineWidth=7;c.lineCap='round';c.beginPath();c.moveTo(ix,iy+h);c.lineTo(ix,iy);c.lineTo(ix+w,iy);c.lineTo(ix+w,iy+h);c.stroke()});
const LOGO=Gfx.image('img/logo.png');
Gfx.backdrop=(key,top,bottom,accent,W,H,logoAlpha)=>Gfx.texture('backdrop_'+key,W,H,1.5,c=>{grad(c,top,bottom,W,H);c.strokeStyle=accent;c.globalAlpha=.07;c.lineWidth=1;c.beginPath();for(let x=0;x<=W;x+=30){c.moveTo(x,0);c.lineTo(x,H)}for(let y=0;y<=H;y+=30){c.moveTo(0,y);c.lineTo(W,y)}c.stroke();c.globalAlpha=1;
 if(LOGO.cv.width>1){c.globalAlpha=logoAlpha==null?.07:logoAlpha;c.drawImage(LOGO.cv,W/2-150,H/2-150,300,300);c.globalAlpha=1}
 const v=c.createRadialGradient(W/2,H/2,220,W/2,H/2,560);v.addColorStop(0,'rgba(0,0,0,0)');v.addColorStop(1,'rgba(0,0,0,.55)');c.fillStyle=v;c.fillRect(0,0,W,H)});
Gfx.logo=LOGO;

/* ---------- Aktionen ---------- */
class Act{constructor(){this.timing=null}
 inst(n){return null}}
const T=(a,k)=>a.timing==='in'?ease.in(k):a.timing==='out'?ease.out(k):a.timing==='inout'?ease.inout(k):k;
function mk(dur,start,upd,rev){const a=new Act();a.dur=dur;a.start=start;a.upd=upd;a.rev=rev;
 a.inst=function(n){const self=this;let t=0,st=null;return{step(dt){if(st===null)st=self.start?self.start(n):{};t+=dt;const k=self.dur<=0?1:Math.min(1,t/self.dur);self.upd&&self.upd(n,st,T(self,k));if(t>=self.dur){return t-self.dur}return -1}}};
 a.reversed=function(){return this.rev?this.rev():this};return a}
const A={
 wait:d=>mk(d,null,null),
 moveBy:(dx,dy,d)=>mk(d,n=>({x:n.x,y:n.y}),(n,s,k)=>{n.x=s.x+dx*k;n.y=s.y+dy*k},()=>A.moveBy(-dx,-dy,d)),
 moveTo:(x,y,d)=>mk(d,n=>({x:n.x,y:n.y}),(n,s,k)=>{n.x=s.x+(x-s.x)*k;n.y=s.y+(y-s.y)*k}),
 moveToX:(x,d)=>mk(d,n=>({x:n.x}),(n,s,k)=>{n.x=s.x+(x-s.x)*k}),
 moveToY:(y,d)=>mk(d,n=>({y:n.y}),(n,s,k)=>{n.y=s.y+(y-s.y)*k}),
 scaleTo:(v,d)=>mk(d,n=>({x:n.sx,y:n.sy}),(n,s,k)=>{n.sx=s.x+(v-s.x)*k;n.sy=s.y+(v-s.y)*k}),
 scaleXTo:(v,d)=>mk(d,n=>({x:n.sx}),(n,s,k)=>{n.sx=s.x+(v-s.x)*k}),
 scaleYTo:(v,d)=>mk(d,n=>({y:n.sy}),(n,s,k)=>{n.sy=s.y+(v-s.y)*k}),
 scaleBy:(v,d)=>mk(d,n=>({x:n.sx,y:n.sy}),(n,s,k)=>{n.sx=s.x*(1+(v-1)*k);n.sy=s.y*(1+(v-1)*k)}),
 fadeTo:(v,d)=>mk(d,n=>({a:n.alpha}),(n,s,k)=>{n.alpha=s.a+(v-s.a)*k}),
 fadeOut:d=>A.fadeTo(0,d),fadeIn:d=>A.fadeTo(1,d),
 rotateBy:(r,d)=>mk(d,n=>({r:n.rot}),(n,s,k)=>{n.rot=s.r+r*k},()=>A.rotateBy(-r,d)),
 rotateTo:(r,d)=>mk(d,n=>({r:n.rot}),(n,s,k)=>{n.rot=s.r+(r-s.r)*k}),
 run:fn=>mk(0,null,(n,s,k)=>{if(!s.d){s.d=1;fn(n)}}),
 remove:()=>mk(0,null,n=>n.removeFromParent()),
 custom:(d,fn)=>mk(d,null,(n,s,k)=>fn(n,k*d)),
 hide:()=>mk(0,null,n=>{n.hidden=true}),
 unhide:()=>mk(0,null,n=>{n.hidden=false}),
 setTexture:tex=>mk(0,null,n=>{n.texture=tex}),
 colorize:(col,f,d)=>mk(d,null,(n,s,k)=>{n.color=col;n.cbf=f*k}),
};
A.sequence=list=>{const a=new Act();a.dur=list.reduce((s,x)=>s+x.dur,0);a.list=list;
 a.inst=function(n){let i=0,cur=null;return{step(dt){while(i<list.length){if(!cur)cur=list[i].inst(n);const r=cur.step(dt);if(r<0)return -1;dt=r;cur=null;i++}return dt}}};
 a.reversed=function(){return A.sequence(list.slice().reverse().map(x=>x.reversed()))};return a};
A.group=list=>{const a=new Act();a.dur=Math.max(0,...list.map(x=>x.dur));
 a.inst=function(n){const rs=list.map(x=>x.inst(n)),done=list.map(()=>-1);return{step(dt){let all=true,min=1e9;rs.forEach((r,i)=>{if(done[i]>=0)return;const v=r.step(dt);if(v<0)all=false;else done[i]=v});if(!done.every(v=>v>=0))return -1;return Math.min(...done)}}};return a};
A.repeat=(act,count)=>{const a=new Act();a.dur=act.dur*count;a.inst=function(n){let i=0,cur=null;return{step(dt){while(i<count){if(!cur)cur=act.inst(n);const r=cur.step(dt);if(r<0)return -1;dt=r;cur=null;i++;if(act.dur<=0&&i>=count)break}return dt}}};return a};
A.forever=act=>{const a=new Act();a.dur=1e9;a.inst=function(n){let cur=null,guard=0;return{step(dt){guard=0;for(;;){if(!cur)cur=act.inst(n);const r=cur.step(dt);if(r<0)return -1;dt=r;cur=null;if(++guard>50)return -1}}}};return a};
const easeIn=a=>{a.timing='in';return a},easeOut=a=>{a.timing='out';return a},easeInOut=a=>{a.timing='inout';return a};

/* ---------- Knoten ---------- */
class Node{constructor(){this.x=0;this.y=0;this.z=0;this.rot=0;this.sx=1;this.sy=1;this.alpha=1;this.hidden=false;this.children=[];this.parent=null;this.runs=[];this.name='';this.dirty=false;this.user=null}
 setScale(s){this.sx=this.sy=s}get scale(){return this.sx}
 setPos(x,y){this.x=x;this.y=y}
 add(c){if(c.parent)c.removeFromParent();c.parent=this;this.children.push(c);this.dirty=true;return c}
 removeFromParent(){const p=this.parent;if(!p)return;const i=p.children.indexOf(this);if(i>=0)p.children.splice(i,1);this.parent=null}
 removeAllChildren(){this.children.forEach(c=>c.parent=null);this.children=[]}
 child(name){return this.children.find(c=>c.name===name)||null}
 run(act,key){if(key)this.removeAction(key);this.runs.push({key:key||null,r:act.inst(this)})}
 removeAction(key){this.runs=this.runs.filter(x=>x.key!==key)}
 removeAllActions(){this.runs=[]}
 hasActions(){return this.runs.length>0}
 step(dt){if(this.runs.length){const rs=this.runs.slice();rs.forEach(x=>{if(!this.runs.includes(x))return;if(x.r.step(dt)>=0){const i=this.runs.indexOf(x);if(i>=0)this.runs.splice(i,1)}})}
  for(let i=0;i<this.children.length;i++)this.children[i].step(dt)}
 draw(c){if(this.hidden||this.alpha<=0)return;c.save();c.translate(this.x,this.y);if(this.rot)c.rotate(this.rot);if(this.sx!==1||this.sy!==1)c.scale(this.sx,this.sy);const pa=c.globalAlpha;c.globalAlpha=pa*this.alpha;this.self(c);this.drawKids(c);c.restore()}
 drawKids(c){const k=this.children;if(!k.length)return;let sorted=true;for(let i=1;i<k.length;i++)if(k[i].z<k[i-1].z){sorted=false;break}
  if(!sorted){const o=k.map((n,i)=>[n,i]).sort((a,b)=>a[0].z-b[0].z||a[1]-b[1]);o.forEach(p=>p[0].draw(c))}else k.forEach(n=>n.draw(c))}
 self(c){}
 /* Punkt aus diesem Knoten in Elternkoordinaten und weiter bis zum Ziel */
 convert(px,py,to){let x=px,y=py,n=this;while(n&&n!==to){const cs=Math.cos(n.rot),sn=Math.sin(n.rot);const xx=x*n.sx,yy=y*n.sy;x=n.x+xx*cs-yy*sn;y=n.y+xx*sn+yy*cs;n=n.parent}return{x,y}}
}
class Sprite extends Node{constructor(tex,w,h,color){super();this.texture=tex||null;this.w=w!=null?w:(tex?tex.w:0);this.h=h!=null?h:(tex?tex.h:0);this.color=color||null;this.cbf=0;this.ax=.5;this.ay=.5;this.add_=false}
 get blend(){return this._b}set blend(v){this._b=v}
 self(c){if(this._b==='add')c.globalCompositeOperation='lighter';const w=this.w,h=this.h;
  if(this.texture){const t=this.texture;if(!t.cv.width||t.cv.width<2&&t.w<2)return;c.save();c.scale(1,-1);const x=-this.ax*w,y=-(1-this.ay)*h;
   if(this.color&&this.cbf>=.999)c.drawImage(t.tinted(this.color),x,y,w,h);else{c.drawImage(t.cv,x,y,w,h);if(this.color&&this.cbf>0){const pa=c.globalAlpha;c.globalAlpha=pa*this.cbf;c.drawImage(t.tinted(this.color),x,y,w,h);c.globalAlpha=pa}}c.restore()}
  else if(this.color){c.fillStyle=this.color;c.fillRect(-this.ax*w,-this.ay*h,w,h)}
  if(this._b==='add')c.globalCompositeOperation='source-over'}}
class Label extends Node{constructor(text,size,color,bold){super();this.text=text;this.size=size||17;this.color=color||'#fff';this.bold=bold!==false;this.ha='center';this.va='center'}
 wrap(c){c.font=`${this.bold?900:700} ${this.size}px ${FONT}`;const words=String(this.text).split(' '),lines=[];let cur='';for(const w of words){const t=cur?cur+' '+w:w;if(cur&&c.measureText(t).width>this.maxW){lines.push(cur);cur=w}else cur=t}if(cur)lines.push(cur);return lines}
 get textH(){if(!this.maxW||!this.text)return this.size;const c=document.createElement('canvas').getContext('2d');return this.wrap(c).length*this.size*1.2}
 self(c){if(this.text==null||this.text==='')return;c.save();c.scale(1,-1);c.font=`${this.bold?900:700} ${this.size}px ${FONT}`;c.fillStyle=this.color;c.textAlign=this.ha;
  if(this.maxW){const lines=this.wrap(c),lh=this.size*1.2,tot=lines.length*lh;c.textBaseline='middle';let y0=this.va==='top'?lh/2:this.va==='bottom'?-tot+lh/2:-tot/2+lh/2;lines.forEach((l,i)=>c.fillText(l,0,y0+i*lh));c.restore();return}
  c.textBaseline=this.va==='center'?'middle':this.va==='top'?'top':this.va==='bottom'?'bottom':'alphabetic';c.fillText(String(this.text),0,this.va==='center'?this.size*.04:0);c.restore()}}
class Shape extends Node{constructor(){super();this.fill=null;this.stroke=null;this.lw=1;this.path=null;this.glow=0;this.cap='butt'}
 static rect(w,h,r){const s=new Shape();s.path=c=>{rr(c,-w/2,-h/2,w,h,r||0)};return s}
 static ellipse(w,h){const s=new Shape();s.path=c=>{c.beginPath();c.ellipse(0,0,w/2,h/2,0,0,7)};return s}
 static circle(r){return Shape.ellipse(r*2,r*2)}
 static line(x1,y1,x2,y2){const s=new Shape();s.path=c=>{c.beginPath();c.moveTo(x1,y1);c.lineTo(x2,y2)};return s}
 self(c){if(!this.path)return;c.beginPath();this.path(c);if(this.glow){c.shadowColor=this.stroke||this.fill;c.shadowBlur=this.glow}if(this.fill){c.fillStyle=this.fill;c.fill()}if(this.stroke){c.strokeStyle=this.stroke;c.lineWidth=this.lw;c.lineCap=this.cap;c.stroke()}}}
class Crop extends Node{constructor(w,h){super();this.mw=w;this.mh=h}
 draw(c){if(this.hidden||this.alpha<=0)return;c.save();c.translate(this.x,this.y);if(this.rot)c.rotate(this.rot);if(this.sx!==1||this.sy!==1)c.scale(this.sx,this.sy);c.beginPath();c.rect(-this.mw/2,-this.mh/2,this.mw,this.mh);c.clip();const pa=c.globalAlpha;c.globalAlpha=pa*this.alpha;this.drawKids(c);c.restore()}}
const label=(text,size,color,bold)=>new Label(text,size,color,bold);
const spr=(tex,w,h)=>new Sprite(tex,w,h);
const box=(color,w,h)=>new Sprite(null,w,h,color);
return{rgba,white,Theme,FONT,clamp,rnd,Rand,Gfx,Texture,A,easeIn,easeOut,easeInOut,Node,Sprite,Label,Shape,Crop,label,spr,box,PI,rr}
})();
