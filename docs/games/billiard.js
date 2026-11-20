(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const rr=(a,b)=>a+Math.random()*(b-a);
const PR=25,MAXPULL=42,COOL=1.5;
class BilliardGame extends MiniScene{
 static get layout(){return 'arena'}
 static get stripThickness(){return 90}
 setupGame(){const n=this.n;this.duration=60;const a=this.arena,T=this.table={x:a.x+6,y:a.y+6,w:a.w-12,h:a.h-12};T.r=T.x+T.w;T.t=T.y+T.h;T.cx=T.x+T.w/2;T.cy=T.y+T.h/2;
  this.puckR=n>=3?11:12;this.cueR=this.puckR+2.5;this.bodies=[];this.states=[];this.soundT=0;this.bounceT=0;this.ending=false;
  const fw=Math.floor(T.w),fh=Math.floor(T.h);
  const felt=new Sprite(Gfx.texture('billiard_felt_'+fw+'x'+fh,fw,fh,1.5,c=>{Gfx.gradientColors(c,rgba(.04,.17,.2),rgba(.02,.09,.14),fw,fh);c.strokeStyle='rgba(51,255,204,.07)';c.lineWidth=1;c.beginPath();for(let x=0;x<fw;x+=26){c.moveTo(x,0);c.lineTo(x,fh)}for(let y=0;y<fh;y+=26){c.moveTo(0,y);c.lineTo(fw,y)}c.stroke();
   c.strokeStyle='rgba(77,255,230,.18)';c.lineWidth=2;c.beginPath();c.moveTo(0,fh/2);c.lineTo(fw,fh/2);c.stroke();c.beginPath();c.arc(fw/2,fh/2,40,0,7);c.stroke()}),fw,fh);
  felt.x=T.cx;felt.y=T.cy;felt.z=-20;this.world.add(felt);
  const d=Math.min(T.w,T.h)*.5,logo=new Sprite(Gfx.logo,d,d);logo.x=T.cx;logo.y=T.cy;logo.alpha=.08;logo.z=-19;this.world.add(logo);
  const rail=new Sprite(Gfx.pill(T.w,T.h,'rgba(0,0,0,0)','rgba(77,255,230,.9)',14,false),T.w,T.h);rail.x=T.cx;rail.y=T.cy;rail.z=-10;this.world.add(rail);
  const rg=new Sprite(Gfx.pill(T.w+12,T.h+12,'rgba(0,0,0,0)','rgba(77,255,230,.25)',18,false),T.w+12,T.h+12);rg.x=T.cx;rg.y=T.cy;rg.z=-11;this.world.add(rg);rg.run(A.forever(A.sequence([A.fadeTo(.4,1),A.fadeTo(1,1)])));
  const pin=5;this.pockets=[{x:T.x+pin,y:T.y+pin},{x:T.r-pin,y:T.y+pin},{x:T.x+pin,y:T.t-pin},{x:T.r-pin,y:T.t-pin}];
  for(const p of this.pockets){const h=new Sprite(Gfx.circle(PR,rgba(0,.02,.04),rgba(1,.3,.85)),PR*2,PR*2);h.x=p.x;h.y=p.y;h.z=-8;this.world.add(h);
   const g=new Sprite(Gfx.glow(),PR*4.2,PR*4.2);g.color=rgba(1,.3,.85);g.cbf=1;g.blend='add';g.alpha=.55;g.x=p.x;g.y=p.y;g.z=-9;this.world.add(g);g.run(A.forever(A.sequence([A.fadeTo(.3,.9),A.fadeTo(.6,.9)])))}
  const total=n===2?10:(n===3?9:8),cols=[];for(let i=0;i<total;i++)cols.push(i%n);for(let i=cols.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[cols[i],cols[j]]=[cols[j],cols[i]]}
  const sp=this.puckR*2+1.5,pts=[];for(let row=-6;row<=6;row++)for(let col=-6;col<=6;col++)pts.push({x:col*sp+(row%2!==0?sp/2:0),y:row*sp*.866});pts.sort((a,b)=>Math.hypot(a.x,a.y)-Math.hypot(b.x,b.y));
  for(let i=0;i<total;i++){const seat=this.seats[cols[i]],b=this.mk(this.puckR,1,seat.index,-1);b.pos={x:T.cx+pts[i].x,y:T.cy+pts[i].y};this.puckNode(b,seat.color,white(1,.9),.5);b.node.x=b.pos.x;b.node.y=b.pos.y;b.node.z=22;this.world.add(b.node);this.bodies.push(b)}
  this.coloured=total;
  for(const s of this.seats){const st={rest:null,cool:0,respawn:0,touch:null,drag:{x:0,y:0},cpuThink:1,dots:[],wasReady:false};
   st.rest=s.toScene({x:s.w>300?0:24,y:s.h/2-32});const cue=this.mk(this.cueR,1.25,-1,s.index);cue.inPlay=false;cue.entered=false;cue.pos={x:st.rest.x,y:st.rest.y};
   this.puckNode(cue,white(.95),s.color,.7,s.color);cue.node.x=st.rest.x;cue.node.y=st.rest.y;cue.node.z=30;this.world.add(cue.node);st.cue=cue;this.bodies.push(cue);
   const g=new Sprite(Gfx.glow(),this.cueR*5,this.cueR*5);g.color=s.color;g.cbf=1;g.blend='add';g.alpha=0;g.x=st.rest.x;g.y=st.rest.y;g.z=28;this.world.add(g);st.readyGlow=g;
   const band=new Sprite(null,4,1,s.color);band.alpha=0;band.z=29;this.world.add(band);st.band=band;
   const hd=new Sprite(Gfx.circle(9,s.color.replace(/[\d.]+\)$/,'.5)'),'#fff'),18,18);hd.alpha=0;hd.z=29;this.world.add(hd);st.handle=hd;
   for(let i=0;i<10;i++){const dt=new Sprite(Gfx.dot(),6,6);dt.color=s.color;dt.cbf=1;dt.blend='add';dt.alpha=0;dt.z=27;this.world.add(dt);st.dots.push(dt)}
   st.cpuThink=1.2+Math.random()*1.2+(1-s.skill)*1.2;this.states.push(st);
   if(!s.isCPU){const h=label('ZIEHEN & LOSLASSEN',11,white(1,.6));h.y=-s.h/2+12;h.z=410;s.node.add(h);h.run(A.sequence([A.wait(8),A.fadeOut(.5),A.remove()]))}}}
 mk(r,mass,owner,cueSeat){return{node:new Node(),pos:{x:0,y:0},vel:{x:0,y:0},r,mass,owner,cueSeat,lastHit:-1,alive:true,inPlay:true,entered:true,stopT:0,trailT:0,get isCue(){return this.cueSeat>=0},get active(){return this.alive&&(!this.isCue||this.inPlay)}}}
 puckNode(b,color,ring,ga,gc){const g=new Sprite(Gfx.glow(),b.r*4.2,b.r*4.2);g.color=gc||color;g.cbf=1;g.blend='add';g.alpha=ga;g.z=-1;b.node.add(g);
  b.node.add(new Sprite(Gfx.circle(b.r,color,ring),b.r*2,b.r*2));const hi=new Sprite(Gfx.circle(b.r*.45,white(1,.35),null),b.r*.9,b.r*.9);hi.x=-b.r*.25;hi.y=b.r*.25;hi.z=1;b.node.add(hi)}
 ready(st){return!st.cue.inPlay&&st.cool<=0&&st.respawn<=0}
 began(seat,at,id){const st=this.states[seat.index];if(st.touch!==null||!this.ready(st))return;st.touch=id;st.drag=seat.toScene(at);this.updateAim(seat,st)}
 moved(seat,at,id){const st=this.states[seat.index];if(st.touch!==id)return;st.drag=seat.toScene(at);this.updateAim(seat,st)}
 ended(seat,at,id){const st=this.states[seat.index];if(st.touch!==id)return;st.drag=seat.toScene(at);st.touch=null;const pi=this.pullInfo(seat,st);this.hideAim(st);if(pi.valid&&this.ready(st))this.fire(seat,st,pi.dir,260+pi.frac*640)}
 pullInfo(seat,st){const dx=st.rest.x-st.drag.x,dy=st.rest.y-st.drag.y,len=Math.hypot(dx,dy);if(len<1)return{dir:{x:0,y:0},frac:0,valid:false};
  const dir={x:dx/len,y:dy/len},inw=seat.dirToScene({dx:0,dy:1});return{dir,frac:Math.min(1,len/MAXPULL),valid:len>=10&&dir.x*inw.dx+dir.y*inw.dy>.2}}
 updateAim(seat,st){const pi=this.pullInfo(seat,st),dx=st.drag.x-st.rest.x,dy=st.drag.y-st.rest.y,len=Math.hypot(dx,dy),hl=Math.min(len,MAXPULL),hp=len>.5?{x:st.rest.x+dx/len*hl,y:st.rest.y+dy/len*hl}:st.rest;
  st.handle.x=hp.x;st.handle.y=hp.y;st.handle.alpha=.9;st.band.x=(hp.x+st.rest.x)/2;st.band.y=(hp.y+st.rest.y)/2;st.band.h=Math.max(1,hl);st.band.rot=Math.atan2(hp.y-st.rest.y,hp.x-st.rest.x)-Math.PI/2;st.band.alpha=pi.valid?.8:.25;
  const count=pi.valid?3+Math.floor(pi.frac*7):0;st.dots.forEach((dt,i)=>{if(i<count){const dd=this.cueR+14+i*24;dt.x=st.rest.x+pi.dir.x*dd;dt.y=st.rest.y+pi.dir.y*dd;dt.alpha=.85-i*.07}else dt.alpha=0})}
 hideAim(st){st.handle.alpha=0;st.band.alpha=0;st.dots.forEach(d=>d.alpha=0)}
 fire(seat,st,dir,speed){const c=st.cue;c.pos={x:st.rest.x,y:st.rest.y};c.vel={x:dir.x*speed,y:dir.y*speed};c.inPlay=true;c.entered=false;c.stopT=0;c.node.removeAction('pop');c.node.setScale(1);c.node.alpha=1;c.node.x=c.pos.x;c.node.y=c.pos.y;st.cool=COOL;st.readyGlow.removeAction('pulse');st.readyGlow.alpha=0;
  Sfx.play(speed>650?'kick':'tap');if(!seat.isCPU)Haptic.tap(speed>650?'heavy':'medium');c.node.run(A.sequence([A.scaleTo(1.25,.05),A.scaleTo(1,.1)]),'pop');
  this.sparkAt(st.rest,seat.color,speed>650?8:4,60+speed*.08)}
 gameUpdate(dt){this.soundT-=dt;this.bounceT-=dt;
  for(const s of this.seats){const st=this.states[s.index];if(st.cool>0)st.cool-=dt;if(st.respawn>0){st.respawn-=dt;if(st.respawn<=0)this.respawnCue(st)}
   if(!st.cue.inPlay){const rd=this.ready(st),cn=st.cue.node;if(st.respawn<=0)cn.alpha=rd?1:.35;
    if(rd&&!st.wasReady){st.readyGlow.removeAction('pulse');st.readyGlow.alpha=.8;st.readyGlow.run(A.forever(A.sequence([A.fadeTo(.25,.6),A.fadeTo(.65,.6)])),'pulse');if(s.isCPU)st.cpuThink=.35+(1-s.skill)*1.6+Math.random()*.7}
    if(!rd&&st.wasReady){st.readyGlow.removeAction('pulse');st.readyGlow.alpha=0}st.wasReady=rd;if(s.isCPU&&rd){st.cpuThink-=dt;if(st.cpuThink<=0)this.cpuShoot(s,st)}}else st.wasReady=false}
  const steps=3,sdt=dt/steps;for(let k=0;k<steps;k++){for(const b of this.bodies)if(b.active){b.pos.x+=b.vel.x*sdt;b.pos.y+=b.vel.y*sdt}for(const b of this.bodies)if(b.active)this.walls(b);for(const b of this.bodies)if(b.active&&b.entered)this.checkPockets(b);this.collisions()}
  const fr=Math.pow(.33,dt);
  for(const b of this.bodies){if(!b.active)continue;let vx=b.vel.x*fr,vy=b.vel.y*fr;const sp=Math.hypot(vx,vy);if(sp>0){const ns=Math.max(0,sp-22*dt);vx=vx/sp*ns;vy=vy/sp*ns;if(ns<12){vx=0;vy=0}}b.vel={x:vx,y:vy};b.node.x=b.pos.x;b.node.y=b.pos.y;const speed=Math.hypot(vx,vy);
   if(speed>260){b.trailT-=dt;if(b.trailT<=0){b.trailT=.028;this.trail(b)}}
   if(b.isCue&&b.inPlay){if(speed===0){b.stopT+=dt;if(b.stopT>.4)this.retireCue(b)}else b.stopT=0}}
  if(this.coloured<=0&&!this.ending){this.ending=true;this.bannerAll('ALLE VERSENKT!','#ff0',34,.7);this.flashAll('#ff0',.25);this.finishGame()}}
 trail(b){const t=new Sprite(Gfx.glow(),b.r*2.8,b.r*2.8);t.color=b.isCue?this.seats[b.cueSeat].color:this.seats[b.owner].color;t.cbf=1;t.blend='add';t.alpha=.45;t.x=b.pos.x;t.y=b.pos.y;t.z=15;this.world.add(t);t.run(A.sequence([A.group([A.fadeOut(.3),A.scaleTo(.3,.3)]),A.remove()]))}
 walls(b){const T=this.table,minX=T.x+b.r,maxX=T.r-b.r,minY=T.y+b.r,maxY=T.t-b.r;
  if(!b.entered){if(b.isCue){if(b.pos.x>=minX&&b.pos.x<=maxX&&b.pos.y>=minY&&b.pos.y<=maxY){b.entered=true;return}const e=this.seats[b.cueSeat].edge;
    if(e==='bottom'||e==='top'){if(b.pos.x<minX){b.pos.x=minX;b.vel.x=Math.abs(b.vel.x)}if(b.pos.x>maxX){b.pos.x=maxX;b.vel.x=-Math.abs(b.vel.x)}}
    else{if(b.pos.y<minY){b.pos.y=minY;b.vel.y=Math.abs(b.vel.y)}if(b.pos.y>maxY){b.pos.y=maxY;b.vel.y=-Math.abs(b.vel.y)}}}return}
  let hit=false;if(b.pos.x<minX){b.pos.x=minX;b.vel.x=Math.abs(b.vel.x)*.9;hit=true}if(b.pos.x>maxX){b.pos.x=maxX;b.vel.x=-Math.abs(b.vel.x)*.9;hit=true}if(b.pos.y<minY){b.pos.y=minY;b.vel.y=Math.abs(b.vel.y)*.9;hit=true}if(b.pos.y>maxY){b.pos.y=maxY;b.vel.y=-Math.abs(b.vel.y)*.9;hit=true}
  if(hit&&this.bounceT<=0&&Math.hypot(b.vel.x,b.vel.y)>200){this.bounceT=.06;Sfx.play('bounce')}}
 collisions(){const B=this.bodies,c=B.length;for(let i=0;i<c-1;i++){const a=B[i];if(!a.active)continue;for(let j=i+1;j<c;j++){const b=B[j];if(!b.active)continue;const dx=b.pos.x-a.pos.x,dy=b.pos.y-a.pos.y,minD=a.r+b.r;if(Math.abs(dx)>minD||Math.abs(dy)>minD)continue;const d2=dx*dx+dy*dy;if(d2>=minD*minD||d2<1e-4)continue;
   const d=Math.sqrt(d2),nx=dx/d,ny=dy/d,tm=a.mass+b.mass,ov=minD-d;a.pos.x-=nx*ov*(b.mass/tm);a.pos.y-=ny*ov*(b.mass/tm);b.pos.x+=nx*ov*(a.mass/tm);b.pos.y+=ny*ov*(a.mass/tm);
   const rv=(b.vel.x-a.vel.x)*nx+(b.vel.y-a.vel.y)*ny;if(rv>=0)continue;const e=.94,jm=-(1+e)*rv/(1/a.mass+1/b.mass),spA=Math.hypot(a.vel.x,a.vel.y),spB=Math.hypot(b.vel.x,b.vel.y);
   a.vel.x-=jm*nx/a.mass;a.vel.y-=jm*ny/a.mass;b.vel.x+=jm*nx/b.mass;b.vel.y+=jm*ny/b.mass;
   if(a.isCue&&!b.isCue)b.lastHit=a.cueSeat;else if(b.isCue&&!a.isCue)a.lastHit=b.cueSeat;else if(!a.isCue&&!b.isCue){if(spA>=spB&&a.lastHit>=0)b.lastHit=a.lastHit;else if(spB>spA&&b.lastHit>=0)a.lastHit=b.lastHit}
   if(-rv>90&&this.soundT<=0){this.soundT=.05;Sfx.play(-rv>400?'hit':'tap');const p={x:a.pos.x+nx*a.r,y:a.pos.y+ny*a.r};if(-rv>300)this.sparkAt(p,'#fff',4,40);
    if(-rv>300){const col=a.isCue?this.seats[a.cueSeat].color:b.isCue?this.seats[b.cueSeat].color:'#fff';const ring=new Sprite(Gfx.circle(8,'rgba(0,0,0,0)',col),16,16);ring.blend='add';ring.x=p.x;ring.y=p.y;ring.z=38;this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(2.2,.22),A.fadeOut(.22)]),A.remove()]))}}}}}
 sparkAt(p,color,count,speed){for(let i=0;i<count;i++){const s=new Sprite(Gfx.dot(),5,5);s.color=color;s.cbf=1;s.blend='add';s.x=p.x;s.y=p.y;s.z=40;this.world.add(s);const a=Math.random()*6.28,r=rr(.4,1)*speed;s.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.3),A.fadeOut(.3)]),A.remove()]))}}
 checkPockets(b){for(const p of this.pockets)if(Math.hypot(b.pos.x-p.x,b.pos.y-p.y)<PR-1){this.pocketed(b,p);return}}
 pocketed(b,p){const color=b.isCue?this.seats[b.cueSeat].color:this.seats[b.owner].color;this.pocketBurst(p,color);Sfx.play('pop');
  this.world.removeAction('shk');this.world.x=0;this.world.y=0;this.world.run(A.sequence([A.moveBy(3,0,.025),A.moveBy(-6,0,.04),A.moveBy(3,0,.025)]),'shk');
  const to=A.group([A.moveTo(p.x,p.y,.12),A.scaleTo(.1,.12)]);
  if(b.isCue){b.vel={x:0,y:0};b.inPlay=false;b.node.run(A.sequence([to,A.fadeOut(.01)]));const st=this.states[b.cueSeat];st.respawn=.5;st.cool=Math.max(st.cool,.6);return}
  b.alive=false;this.coloured--;b.vel={x:0,y:0};b.node.run(A.sequence([to,A.remove()]));
  if(b.lastHit>=0){const s=this.seats[b.lastHit],own=b.owner===b.lastHit,pts=own?2:1;this.addScore(s,pts);this.addStat('balls',1,s);let lp=s.local(p);const lim=s.w/2-70;lp.x=Math.max(-lim,Math.min(lim,lp.x));lp.y=Math.max(-s.h/2+20,Math.min(s.h/2+400,lp.y));
   s.floatText('VERSENKT +'+pts,lp,own?'#ff0':s.color,s.w<250?15:19);if(own)this.flashAll(s.color,.12);if(!s.isCPU)Haptic.tap(own?'heavy':'medium');Sfx.play(own?'coin':'right')}else Sfx.play('miss')}
 pocketBurst(p,color){const ring=new Sprite(Gfx.circle(PR,'rgba(0,0,0,0)',color),PR*2,PR*2);ring.x=p.x;ring.y=p.y;ring.z=38;ring.blend='add';this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(2.4,.35),A.fadeOut(.35)]),A.remove()]));
  for(let i=0;i<16;i++){const d=new Sprite(Gfx.dot(),8,8);d.color=color;d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=40;this.world.add(d);const a=Math.random()*6.28,r=rr(30,110);d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.5),A.fadeOut(.5),A.scaleTo(.2,.5)]),A.remove()]))}}
 retireCue(b){const st=this.states[b.cueSeat];b.inPlay=false;b.vel={x:0,y:0};b.node.run(A.fadeOut(.2));st.respawn=.2}
 respawnCue(st){const c=st.cue;c.inPlay=false;c.entered=false;c.vel={x:0,y:0};c.pos={x:st.rest.x,y:st.rest.y};c.node.removeAction('pop');c.node.x=st.rest.x;c.node.y=st.rest.y;c.node.alpha=.35;c.node.setScale(.1);c.node.run(A.scaleTo(1,.2),'pop')}
 cpuShoot(s,st){const c=st.rest,targets=this.bodies.filter(b=>!b.isCue&&b.alive);if(!targets.length){st.cpuThink=1;return}const inw=s.dirToScene({dx:0,dy:1}),T=this.table,cr=this.cueR,cands=[];
  for(const p of targets)for(const k of this.pockets){const vx=k.x-p.pos.x,vy=k.y-p.pos.y,len=Math.max(1,Math.hypot(vx,vy)),ux=vx/len,uy=vy/len,g={x:p.pos.x-ux*(p.r+cr),y:p.pos.y-uy*(p.r+cr)};
   if(g.x<T.x+cr||g.x>T.r-cr||g.y<T.y+cr||g.y>T.t-cr)continue;const tx=g.x-c.x,ty=g.y-c.y,d1=Math.max(1,Math.hypot(tx,ty)),dx=tx/d1,dy=ty/d1;if(dx*inw.dx+dy*inw.dy<.25)continue;const cut=dx*ux+dy*uy;if(cut<.35)continue;
   let blocked=false;for(const o of targets){if(o===p)continue;const ox=o.pos.x-c.x,oy=o.pos.y-c.y,t=Math.max(0,Math.min(d1,ox*dx+oy*dy)),px=c.x+dx*t,py=c.y+dy*t;if(Math.hypot(o.pos.x-px,o.pos.y-py)<o.r+cr+1){blocked=true;break}}
   let sc=cut*100-(d1+len)*.06;if(p.owner===s.index)sc+=30;if(blocked)sc-=70;cands.push({score:sc,aim:g,dist:d1+len})}
  let aim,dist;if(!cands.length){const p=targets.reduce((m,o)=>Math.hypot(o.pos.x-c.x,o.pos.y-c.y)<Math.hypot(m.pos.x-c.x,m.pos.y-c.y)?o:m);aim=p.pos;dist=Math.hypot(p.pos.x-c.x,p.pos.y-c.y)+200}
  else{cands.sort((a,b)=>b.score-a.score);const top=Math.random()<.35+s.skill*.6,idx=top?0:Math.floor(Math.random()*Math.min(3,cands.length));aim=cands[idx].aim;dist=cands[idx].dist}
  const ang=Math.atan2(aim.y-c.y,aim.x-c.x),err=rr(-1,1)*(1-s.skill)*.24+rr(-.012,.012),a2=ang+err;let dir={x:Math.cos(a2),y:Math.sin(a2)};if(dir.x*inw.dx+dir.y*inw.dy<.2)dir={x:inw.dx,y:inw.dy};
  let speed=dist*1.25+220;speed*=1+rr(-1,1)*(1-s.skill)*.25;speed=Math.max(300,Math.min(900,speed));this.fire(s,st,dir,speed);st.cpuThink=1}
 timeUp(){this.finishGame()}
}
Arcade.register('billiard',BilliardGame);
})();
