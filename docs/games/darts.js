(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const N=6,rr=(a,b)=>a+Math.random()*(b-a);
const boardTex=(R,col,idx)=>{const sz=R*2+12;return Gfx.texture('darts_board_'+Math.floor(R)+'_'+idx,sz,sz,2,c=>{const cx=sz/2,cy=sz/2,disc=(r,f)=>{c.fillStyle=f;c.beginPath();c.arc(cx,cy,r,0,7);c.fill()};
 disc(R+3,'rgb(8,8,8)');const W=12;for(let i=0;i<W;i++){const a0=i/W*2*Math.PI,a1=(i+1)/W*2*Math.PI;c.beginPath();c.moveTo(cx,cy);c.arc(cx,cy,R,a0,a1,false);c.closePath();c.fillStyle=i%2===0?alpha(col,.2):'rgb(26,26,26)';c.fill()}
 disc(R*.3,'rgb(15,15,15)');disc(R*.3,alpha(col,.3));disc(R*.12,'rgba(255,51,51,.95)');c.lineWidth=2.2;
 for(const[f,a]of[[1,1],[.62,.85],[.3,.9],[.12,1]]){c.strokeStyle=f===.12?'#fff':alpha(col,a);c.beginPath();c.arc(cx,cy,R*f,0,7);c.stroke()}
 c.strokeStyle='rgba(255,255,255,.9)';c.lineWidth=1.2;c.beginPath();c.arc(cx,cy,R,0,7);c.stroke()})};
const crossTex=()=>Gfx.texture('darts_cross',40,40,2,c=>{c.strokeStyle='#fff';c.lineWidth=2;c.beginPath();c.arc(20,20,12,0,7);c.moveTo(20,1);c.lineTo(20,13);c.moveTo(20,27);c.lineTo(20,39);c.moveTo(1,20);c.lineTo(13,20);c.moveTo(27,20);c.lineTo(39,20);c.stroke();c.fillStyle='#fff';c.beginPath();c.arc(20,20,1.5,0,7);c.fill()});
const dartTex=(col,idx)=>Gfx.texture('darts_dart_'+idx,20,42,2,c=>{c.fillStyle='rgb(217,217,217)';c.beginPath();c.moveTo(8,16);c.lineTo(12,16);c.lineTo(10.8,33);c.lineTo(10,42);c.lineTo(9.2,33);c.closePath();c.fill();c.fillStyle='rgb(115,115,115)';c.fillRect(8.6,22,2.8,3);
 c.fillStyle=col;c.beginPath();c.ellipse(10,11.25,5.5,4.75,0,0,7);c.fill();for(const[x,y]of[[3,3.8],[7.6,1.2],[12.4,1.2],[17,3.8]]){c.beginPath();c.ellipse(x,y,2.1,2.3,0,0,7);c.fill()}c.strokeStyle='rgba(255,255,255,.85)';c.lineWidth=.8;c.beginPath();c.ellipse(10,11.25,5.5,4.75,0,0,7);c.stroke()});
const pipTex=()=>Gfx.texture('darts_pip',10,22,2,c=>{c.fillStyle='#fff';c.beginPath();c.moveTo(3,1);c.lineTo(7,1);c.lineTo(7,12);c.lineTo(5,21);c.lineTo(3,12);c.closePath();c.fill()});
class DartsGame extends MiniScene{
 static get layout(){return 'turns'}
 setupGame(){this.duration=0;const r0=this.newRand(),px=r0.range(0,6.28),py=r0.range(0,6.28);this.boards=[];
  for(const s of this.seats){const b={R:Math.min(s.w*.43,132,(s.h-96)/2),center:{x:0,y:-4},thrown:0,phx:px,phy:py,fx:1,fy:1.37,pips:[],lastThrow:0,cpuReady:.7+(1-s.skill)*.9+Math.random()*.4,cpuFireAt:null,done:false,doneAt:0};
   const glow=new Sprite(Gfx.glow(),b.R*2.9,b.R*2.9);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.35;glow.x=b.center.x;glow.y=b.center.y;glow.z=1;s.field.add(glow);glow.run(A.forever(A.sequence([A.fadeTo(.22,1),A.fadeTo(.38,1)])));
   const board=new Sprite(boardTex(b.R,s.color,s.index),b.R*2+12,b.R*2+12);board.x=b.center.x;board.y=b.center.y;board.z=2;s.field.add(board);
   for(const[f,t]of[[.81,'5'],[.46,'10'],[.21,'25']]){const l=label(t,Math.max(8,b.R*.11),white(1,.55));l.x=b.center.x+b.R*f;l.y=b.center.y-3;l.z=3;s.field.add(l)}
   const cg=new Sprite(Gfx.glow(),46,46);cg.blend='add';cg.alpha=.55;cg.z=80;s.field.add(cg);b.crossGlow=cg;const cr=new Sprite(crossTex(),34,34);cr.z=81;s.field.add(cr);b.cross=cr;
   const gap=Math.min(20,(s.w-40)/N);for(let i=0;i<N;i++){const p=new Sprite(pipTex(),8,17);p.color=s.color;p.cbf=1;p.x=(i-(N-1)/2)*gap;p.y=-s.h/2+16;p.z=5;s.field.add(p);b.pips.push(p)}
   const hint=label(s.isCPU?'CPU':'TIPP = WERFEN',Math.min(16,s.w*.08),'#fff');hint.y=-s.h/2+40;hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.4),A.fadeOut(.4),A.remove()]));b.hint=hint;
   this.boards.push(b);this.updateCross(s,b)}
  this.setActiveSeat(0)}
 speedMult(b){return 1+.22*b.thrown}
 crossPos(b){const a=b.R*.8;return{x:b.center.x+a*Math.sin(b.phx),y:b.center.y+a*Math.sin(b.phy)}}
 updateCross(s,b){const p=this.crossPos(b);b.cross.x=p.x;b.cross.y=p.y;b.crossGlow.x=p.x;b.crossGlow.y=p.y;b.crossGlow.color=s.color;b.crossGlow.cbf=1}
 points(b,d){const f=d/b.R;if(f<.12)return 50;if(f<.3)return 25;if(f<.62)return 10;if(f<=1)return 5;return 0}
 throwDart(s){const b=this.boards[s.index];if(b.done||b.thrown>=N)return;const p=this.crossPos(b),d=Math.hypot(p.x-b.center.x,p.y-b.center.y),pts=this.points(b,d);b.thrown++;b.lastThrow=this.elapsed;b.cpuFireAt=null;b.cpuReady=this.elapsed+.55+(1-s.skill)*.8+Math.random()*.35;
  if(b.hint){b.hint.removeFromParent();b.hint=null}
  if(b.thrown-1<b.pips.length){b.pips[b.thrown-1].run(A.group([A.fadeOut(.15),A.scaleTo(.2,.15)]))}
  const dart=new Sprite(dartTex(s.color,s.index),17,36);dart.ay=0;dart.x=p.x;dart.y=p.y;dart.rot=rr(-.3,.1);dart.z=20+b.thrown;dart.setScale(2.2);dart.alpha=.2;s.field.add(dart);
  dart.run(A.sequence([A.group([A.scaleTo(1,.08),A.fadeIn(.06)]),A.scaleTo(1.12,.04),A.scaleTo(1,.06)]));
  const ring=new Sprite(Gfx.circle(10,'rgba(0,0,0,0)','#fff'),20,20);ring.x=p.x;ring.y=p.y;ring.z=15;ring.setScale(.3);ring.alpha=.9;s.field.add(ring);ring.run(A.sequence([A.group([A.scaleTo(1.6,.25),A.fadeOut(.25)]),A.remove()]));
  b.cross.run(A.sequence([A.scaleTo(1.5,.05),A.scaleTo(1,.15)]));
  if(pts>0){this.addScore(s,pts);this.addStat('hits',1,s)}const top={x:p.x,y:p.y+14};
  if(pts===50){s.floatText('BULLSEYE! +50',top,'#ff0',Math.min(26,s.w*.11));s.burst(p,'#ff0',34,190);s.burst(p,'#fff',16,120);s.flash('#ff0',.4);s.shake(9);Sfx.play('fanfare');if(!s.isCPU)Haptic.good()}
  else if(pts===25){s.floatText('+25',top,s.color,24);s.burst(p,s.color,18,130);Sfx.play('coin');if(!s.isCPU)Haptic.tap('medium')}
  else if(pts===10){s.floatText('+10',top,'#fff',21);s.burst(p,s.color,10,100);Sfx.play('hit');if(!s.isCPU)Haptic.tap('medium')}
  else if(pts===5){s.floatText('+5',top,white(.9),19);s.burst(p,s.color,6,75);Sfx.play('stomp');if(!s.isCPU)Haptic.tap('light')}
  else{s.floatText('DANEBEN',top,rgba(1,.4,.4),17);Sfx.play('miss');if(!s.isCPU)Haptic.bad()}
  if(b.thrown>=N){b.done=true;b.doneAt=this.elapsed;b.cross.run(A.fadeOut(.2));b.crossGlow.run(A.fadeOut(.2));s.banner(''+s.score,s.color,54,1.2)}}
 startTurn(i){const s=this.seats[i],b=this.boards[i];b.lastThrow=this.elapsed;b.cpuFireAt=null;b.cpuReady=this.elapsed+.8+(1-s.skill)*.9+Math.random()*.4;this.setActiveSeat(i)}
 nextTurn(i){for(let k=1;k<=Math.max(1,this.seats.length);k++){const j=(i+k)%this.seats.length;if(!this.boards[j].done)return j}return null}
 gameUpdate(dt){const s=this.seats[this.activeSeatIndex],b=this.boards[s.index];
  if(!b.done){const m=this.speedMult(b);b.phx+=1.75*b.fx*m*dt;b.phy+=1.75*b.fy*m*dt;this.updateCross(s,b);
   if(s.isCPU){if(b.cpuFireAt===null&&this.elapsed>=b.cpuReady){const p=this.crossPos(b),d=Math.hypot(p.x-b.center.x,p.y-b.center.y),waited=this.elapsed-b.cpuReady,thr=b.R*(.1+(1-s.skill)*.45)+waited*b.R*.35;if(d<thr)b.cpuFireAt=this.elapsed+.03+(1-s.skill)*.16+Math.random()*.05}
    if(b.cpuFireAt!==null&&this.elapsed>=b.cpuFireAt)this.throwDart(s)}
   else if(this.elapsed-b.lastThrow>9)this.throwDart(s)}
  else if(this.elapsed-b.doneAt>1.1){const nx=this.nextTurn(s.index);if(nx!==null)this.startTurn(nx)}
  if(this.boards.every(x=>x.done)){const last=Math.max(...this.boards.map(x=>x.doneAt));if(this.elapsed-last>.9)this.finishGame()}}
 began(seat){if(seat.isCPU)return;const b=this.boards[seat.index];if(b.done)return;if(this.elapsed-b.lastThrow<.18)return;this.throwDart(seat)}
}
Arcade.register('darts',DartsGame);
})();
