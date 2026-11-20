(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const FT=.62,REF=140;
const ballTex=(col,idx)=>Gfx.texture('hoops_ball_'+idx,34,34,2,c=>{c.fillStyle=col;c.beginPath();c.arc(17,17,16,0,7);c.fill();c.fillStyle='rgba(255,255,255,.28)';c.beginPath();c.ellipse(13,9,7,5,0,0,7);c.fill();
 c.fillStyle='rgba(13,13,13,.85)';c.beginPath();c.arc(17,17,3,0,7);c.fill();for(let i=0;i<6;i++){const a=i*Math.PI/3+.3;c.beginPath();c.arc(17+Math.cos(a)*9.5,17+Math.sin(a)*9.5,2.2,0,7);c.fill()}c.strokeStyle='rgba(255,255,255,.9)';c.lineWidth=1.3;c.beginPath();c.arc(17,17,16,0,7);c.stroke()});
const boardTex=(w,col,idx)=>{const h=w*.72;return Gfx.texture('hoops_board_'+Math.floor(w)+'_'+idx,w,h,2,c=>{SK.rr(c,2,2,w-4,h-4,6);c.fillStyle='rgba(255,255,255,.10)';c.fill();c.strokeStyle=col;c.lineWidth=2.5;c.stroke();c.strokeStyle='rgba(255,255,255,.75)';c.lineWidth=1.6;c.strokeRect(w*.32,h*.38,w*.36,h*.45)})};
const netTex=(w,h)=>Gfx.texture('hoops_net_'+Math.floor(w),w,h,2,c=>{c.strokeStyle='rgba(255,255,255,.85)';c.lineWidth=1.3;const n=6;c.beginPath();
 for(let i=0;i<=n;i++){const tx=w*i/n,bx=w*.2+w*.6*i/n;c.moveTo(tx,0);c.lineTo(bx,h);if(i<n){const tx2=w*(i+1)/n,bx2=w*.2+w*.6*(i+1)/n;c.moveTo(tx,0);c.lineTo(bx2,h);c.moveTo(tx2,0);c.lineTo(bx,h)}}
 for(let j=1;j<=3;j++){const y=h*j/4,inset=w*.2*j/4;c.moveTo(inset,y);c.lineTo(w-inset,y)}c.stroke()});
const rimTex=(w,col)=>Gfx.texture('hoops_rim_'+Math.floor(w),w,14,2,c=>{c.fillStyle=col;c.beginPath();c.ellipse(w/2,7,(w-2)/2,4,0,0,7);c.fill();c.fillStyle='rgb(10,10,10)';c.beginPath();c.ellipse(w/2,7,(w-8)/2,2,0,0,7);c.fill()});
const lineTex=()=>Gfx.texture('hoops_aim',6,64,2,c=>{c.fillStyle='#fff';for(let i=0;i<5;i++){c.beginPath();c.arc(3,62-i*13-2,1.5,0,7);c.fill()}});
class HoopsGame extends MiniScene{
 setupGame(){this.duration=30;this.hoops=[];
  for(const s of this.seats){const h={rimHalf:Math.min(34,s.w*.115+8),hoopY:s.h/2-78,phase:0,x:0,inFlight:false,respawnAt:0,streak:0,dragStart:null,cpuAt:1+Math.random()*.8,ball:null,flight:null};h.range=Math.max(10,s.w/2-h.rimHalf-20);h.home={x:0,y:-s.h/2+44};
   const line=new Sprite(null,s.w-24,2,alpha(s.color,.35));line.y=-s.h/2+76;line.z=1;s.field.add(line);
   const spot=new Sprite(Gfx.glow(),90,90);spot.color=s.color;spot.cbf=1;spot.blend='add';spot.alpha=.3;spot.x=h.home.x;spot.y=h.home.y;spot.z=1;s.field.add(spot);
   const root=new Node();root.y=h.hoopY;root.z=10;s.field.add(root);h.root=root;const bw=h.rimHalf*2*1.55;
   const board=new Sprite(boardTex(bw,s.color,s.index),bw,bw*.72);board.y=bw*.36-2+6;root.add(board);
   const bg=new Sprite(Gfx.glow(),bw*1.7,bw*1.4);bg.color=s.color;bg.cbf=1;bg.blend='add';bg.alpha=.3;bg.y=bw*.3;bg.z=-1;root.add(bg);h.bglow=bg;
   const back=new Sprite(rimTex(h.rimHalf*2,'rgb(255,153,0)'),h.rimHalf*2,14);back.y=3;back.z=1;root.add(back);
   const nh=h.rimHalf*1.25,net=new Sprite(netTex(h.rimHalf*2-6,nh),h.rimHalf*2-6,nh);net.ay=1;net.z=3;root.add(net);h.net=net;
   const front=new Sprite(rimTex(h.rimHalf*2,'rgb(255,153,0)'),h.rimHalf*2,14);front.y=-2;front.z=4;root.add(front);
   const aim=new Sprite(lineTex(),6,64);aim.ay=0;aim.alpha=0;aim.z=8;s.field.add(aim);h.aim=aim;
   const sl=label('',Math.min(18,s.w*.09),'#ff0');sl.y=-s.h/2+100;sl.z=30;sl.alpha=0;s.field.add(sl);h.streakLabel=sl;
   const hint=label(s.isCPU?'CPU':'WISCHEN ↑',Math.min(20,s.w*.1),'#fff');hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.4),A.fadeOut(.4),A.remove()]));h.hint=hint;
   this.hoops.push(h);this.spawnBall(s,h,false)}}
 spawnBall(s,h,animated){const b=new Sprite(ballTex(s.color,s.index),34,34);b.x=h.home.x;b.y=h.home.y;b.z=20;if(animated){b.setScale(.1);b.run(A.scaleTo(1,.18))}
  const gl=new Sprite(Gfx.glow(),64,64);gl.color=s.color;gl.cbf=1;gl.blend='add';gl.alpha=.4;gl.z=-1;b.add(gl);s.field.add(b);h.ball=b;h.inFlight=false}
 launch(s,h,target){const ball=h.ball;if(!ball||h.inFlight)return;h.inFlight=true;if(h.hint){h.hint.removeFromParent();h.hint=null}
  const start={x:ball.x,y:ball.y},Ap={x:Math.max(-s.w/2+10,Math.min(s.w/2-10,target.x)),y:Math.min(target.y,s.h/2-20)};Sfx.play('kick');if(!s.isCPU)Haptic.tap('light');
  ball.removeAllActions();h.flight={t:0,start,A:Ap,dist:Math.max(1,h.hoopY-start.y),tick:0}}
 trailDot(s,p,sc){const d=new Sprite(Gfx.glow(),24,24);d.color=s.color;d.cbf=1;d.blend='add';d.alpha=.7;d.x=p.x;d.y=p.y;d.setScale(sc);d.z=18;s.field.add(d);d.run(A.sequence([A.group([A.fadeOut(.3),A.scaleTo(.2,.3)]),A.remove()]))}
 resolve(s,h,Ap){const ball=h.ball;if(!ball)return;const hx=h.x,dx=Math.abs(Ap.x-hx),dy=Math.abs(Ap.y-(h.hoopY-4)),tolY=Math.max(26,(h.hoopY-h.home.y)*.17),rim={x:hx,y:h.hoopY},ok=dy<tolY;
  if(ok&&dx<h.rimHalf*.58)this.score(s,h,ball,true);
  else if(ok&&dx<h.rimHalf*.95&&Math.random()<.5)this.score(s,h,ball,false);
  else if(ok&&dx<h.rimHalf*1.5){Sfx.play('bounce');if(!s.isCPU)Haptic.tap('rigid');s.burst(rim,'#f90',9,80);h.root.run(A.sequence([A.moveBy(0,-3,.04),A.moveBy(0,3,.06)]));
   const dir=Ap.x>hx?1:-1;ball.z=25;ball.run(A.group([A.moveBy(dir*55,-50,.5),A.rotateBy(dir*-4,.5),A.sequence([A.wait(.25),A.fadeOut(.25)])]));this.miss(s,h,'KLONG!')}
  else{ball.run(A.group([A.moveBy(0,ok?0:(Ap.y>h.hoopY?30:-30),.3),A.fadeOut(.3),A.scaleTo(.4,.3)]));Sfx.play('miss');this.miss(s,h,Ap.y<h.hoopY-tolY?'ZU KURZ':'DANEBEN')}}
 score(s,h,ball,swish){h.streak++;const bonus=h.streak-1,pts=2+bonus;this.addScore(s,pts);this.addStat('goals',1,s);const rim={x:h.x,y:h.hoopY};
  ball.removeAllActions();ball.x=h.x;ball.y=h.hoopY+8;ball.z=10.5;ball.run(A.sequence([A.group([A.moveBy(0,-h.rimHalf*1.3,.28),A.scaleTo(.55,.28)]),A.moveBy(0,-h.rimHalf*.9,.2),A.remove()]));
  h.net.removeAllActions();h.net.run(A.sequence([A.group([A.scaleYTo(1.45,.09),A.scaleXTo(.88,.09)]),A.group([A.scaleYTo(.85,.1),A.scaleXTo(1.08,.1)]),A.group([A.scaleYTo(1,.12),A.scaleXTo(1,.12)])]));
  h.bglow.run(A.sequence([A.fadeTo(.9,.05),A.fadeTo(.3,.4)]));
  s.burst(rim,s.color,swish?26:18,150);s.burst(rim,'#ff0',12,110);
  s.floatText(bonus>0?'+'+pts+'  x'+h.streak:'+'+pts,{x:h.x,y:h.hoopY-30},'#ff0',Math.min(26,s.w*.12));
  if(swish){s.floatText('SWISH!',{x:h.x,y:h.hoopY+h.rimHalf*1.6},'#fff',Math.min(24,s.w*.11));Sfx.play('goal')}else{s.floatText('REIN!',{x:h.x,y:h.hoopY+h.rimHalf*1.6},'#f90',Math.min(22,s.w*.1));Sfx.play('bounce');Sfx.play('coin')}
  s.flash(s.color,.22,.3);if(h.streak>=3)s.shake(5);if(!s.isCPU)Haptic.good();
  if(h.streak>=2){const sl=h.streakLabel;sl.text='SERIE x'+h.streak;sl.removeAllActions();sl.alpha=1;sl.setScale(1.4);sl.run(A.scaleTo(1,.15))}
  h.respawnAt=this.elapsed+.45;h.ball=null;h.flight=null}
 miss(s,h,text){h.streak=0;h.streakLabel.run(A.fadeOut(.2));s.floatText(text,{x:h.x,y:h.hoopY-30},rgba(1,.45,.4),Math.min(18,s.w*.09));if(!s.isCPU)Haptic.bad();const b=h.ball;h.ball=null;h.flight=null;if(b)b.run(A.sequence([A.wait(.5),A.remove()]));h.respawnAt=this.elapsed+.4}
 gameUpdate(dt){const p=Math.min(1,this.elapsed/this.duration);
  for(const s of this.seats){const h=this.hoops[s.index];h.phase+=(.8+1.5*p)*dt;h.x=h.range*Math.sin(h.phase);h.root.x=h.x;
   const f=h.flight;if(f&&h.ball){f.t+=dt;const u=Math.min(1,f.t/FT),lin={x:f.start.x+(f.A.x-f.start.x)*u,y:f.start.y+(f.A.y-f.start.y)*u},lift=Math.sin(u*Math.PI)*46,b=h.ball;b.x=lin.x;b.y=lin.y+lift;
    const depth=Math.max(0,Math.min(1,(lin.y-f.start.y)/f.dist));b.setScale(1-.42*depth+Math.sin(u*Math.PI)*.18);b.rot+=dt*6;
    if(Math.floor(u*14)!==Math.floor(f.tick)){f.tick=u*14;this.trailDot(s,{x:b.x,y:b.y},b.sx)}
    if(u>=1){const Ap=f.A;h.flight=null;this.resolve(s,h,Ap)}}
   if(!h.ball&&this.elapsed>=h.respawnAt){this.spawnBall(s,h,true);h.cpuAt=this.elapsed+.35+(1-s.skill)*.9+Math.random()*.5}
   if(s.isCPU&&!h.inFlight&&h.ball&&this.elapsed>=h.cpuAt){const fp=h.phase+(.8+1.5*p)*FT,hx=h.range*Math.sin(fp),sg=1-s.skill,ex=(Math.random()*2-1)*(sg*55+3),ey=(Math.random()*2-1)*(sg*38+2);this.launch(s,h,{x:hx+ex,y:h.hoopY-4+ey})}}}
 began(seat,at){if(seat.isCPU)return;this.hoops[seat.index].dragStart={x:at.x,y:at.y}}
 moved(seat,at){if(seat.isCPU)return;const h=this.hoops[seat.index],st=h.dragStart,ball=h.ball;if(!st||!ball||h.inFlight){h.aim.alpha=0;return}
  const vx=at.x-st.x,vy=at.y-st.y,len=Math.hypot(vx,vy);if(len<12){h.aim.alpha=0;return}h.aim.alpha=.6;h.aim.x=ball.x;h.aim.y=ball.y+18;h.aim.rot=Math.atan2(vy,vx)-Math.PI/2;h.aim.sy=Math.min(1.6,len/60)}
 ended(seat,at){if(seat.isCPU)return;const h=this.hoops[seat.index];h.aim.alpha=0;const st=h.dragStart;if(!st)return;h.dragStart=null;const ball=h.ball;if(!ball||h.inFlight)return;const vx=at.x-st.x,vy=at.y-st.y;
  if(vy<22){Sfx.play('tap');return}const k=(h.hoopY-ball.y)/REF;this.launch(seat,h,{x:ball.x+vx*k,y:ball.y+vy*k})}
}
Arcade.register('hoops',HoopsGame);
})();
