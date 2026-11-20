(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label,Rand}=SK;
const AIR=.6,NUM=12,SGAP=44;
class HurdlesGame extends MiniScene{
 bearY(s){return -s.h/2+s.h*.24}
 setupGame(){this.duration=40;const r=this.newRand();this.hd=[];let d=260;for(let i=0;i<NUM;i++){this.hd.push(d);d+=r.range(175,235)}this.finishDist=d+40;this.finishedCount=0;this.endTimer=-1;this.cpuRand=new Rand(1+Math.floor(Math.random()*1000000));this.runners=[];
  const colors=[Theme.pink,Theme.blue,Theme.green,Theme.orange];
  for(const s of this.seats){const ru={seat:s,dist:0,bonus:0,stumble:0,airT:-1,combo:0,cleared:0,next:0,finished:false,place:0,hurdles:[],stripes:[],cpuErr:0,cpuSkip:false,cpuJumped:-1,failed:new Set()};this.runners.push(ru);this.buildTrack(ru,colors);
   const hint=label('TIPPEN = SPRUNG',Math.min(22,s.w*.11),'#fff');hint.y=s.h*.12;hint.z=450;s.node.add(hint);hint.run(A.sequence([A.wait(4.2),A.fadeOut(.4),A.remove()]));hint.run(A.forever(A.sequence([A.scaleTo(1.1,.4),A.scaleTo(.95,.4)])),'pp')}}
 buildTrack(ru,colors){const s=ru.seat,tw=s.w*.88,track=new Sprite(null,tw,s.h,white(1,.05));track.z=-30;s.field.add(track);
  for(const sx of[-1,1]){const edge=new Sprite(null,3,s.h,s.color);edge.x=sx*tw/2;edge.z=-29;s.field.add(edge);const g=new Sprite(Gfx.glow(),26,s.h);g.color=s.color;g.cbf=1;g.alpha=.35;g.blend='add';g.x=edge.x;g.z=-29;s.field.add(g)}
  const count=Math.floor(s.h/SGAP)+3;for(let i=0;i<count;i++){const st=new Sprite(null,tw-6,3,white(1,.07));st.z=-28;s.field.add(st);ru.stripes.push(st)}
  const fw=Math.floor(tw-6),tex=Gfx.texture('hurdles_finish'+fw,fw,20,2,c=>{const sq=10;let xi=0;for(let x=0;x<fw;x+=sq){for(let row=0;row<2;row++){c.fillStyle=((xi+row)%2===0)?'#fff':'rgb(26,26,26)';c.fillRect(x,row*sq,sq,sq)}xi++}});
  ru.finishLine=new Sprite(tex,fw,20);ru.finishLine.z=-20;s.field.add(ru.finishLine);
  const hw=tw*.78;
  for(let i=0;i<this.hd.length;i++){const c=colors[i%colors.length],n=new Node(),bar=new Sprite(Gfx.rect(hw,7,c,3),hw,7);bar.y=12;bar.z=1;n.add(bar);
   for(const sx of[-1,1]){const post=new Sprite(Gfx.rect(5,15,white(.85),2),5,15);post.x=sx*hw*.46;post.y=6;n.add(post)}
   const glow=new Sprite(Gfx.glow(),hw*1.3,44);glow.color=c;glow.cbf=1;glow.blend='add';glow.alpha=.6;glow.y=12;n.add(glow);n.z=5;n.hidden=true;s.field.add(n);ru.hurdles.push(n)}
  ru.shadow=new Sprite(Gfx.shadow(),56,20);ru.shadow.z=4;ru.shadow.x=0;ru.shadow.y=this.bearY(s)-2;s.field.add(ru.shadow);
  const bh=Math.min(58,s.w*.3);ru.bear=this.makeBear(s,bh,false);ru.bear.x=0;ru.bear.y=this.bearY(s);ru.bear.z=6;s.field.add(ru.bear);
  const cl=label('',Math.min(18,s.w*.09),'#ff0');cl.x=-s.w/2+14;cl.y=s.h/2-36;cl.ha='left';cl.z=400;s.node.add(cl);ru.comboLabel=cl;this.layoutRunner(ru)}
 gameStarted(){for(const ru of this.runners)ru.bear.startRun(.12)}
 layoutRunner(ru){const s=ru.seat,by=this.bearY(s),top=s.h/2+30;
  this.hd.forEach((hd,i)=>{const y=by+(hd-ru.dist),node=ru.hurdles[i];if(ru.failed.has(i))return;node.hidden=!(y<top&&y>-s.h/2-30);node.x=0;node.y=y});
  const fy=by+(this.finishDist-ru.dist);ru.finishLine.x=0;ru.finishLine.y=fy;ru.finishLine.hidden=fy>top||fy<-s.h/2-20;
  const off=ru.dist%SGAP;ru.stripes.forEach((st,k)=>{st.x=0;st.y=-s.h/2+k*SGAP-off})}
 speed(ru){if(ru.finished)return 0;const slow=ru.stumble>0?(.35+.65*(1-Math.min(1,ru.stumble/.9))):1;return(135+ru.bonus)*slow}
 jump(ru){if(ru.finished||ru.airT>=0)return;ru.airT=0;Sfx.play('jump');if(!ru.seat.isCPU)Haptic.tap('light');
  ru.bear.visual.run(A.sequence([A.scaleYTo(1.15,.08),A.scaleYTo(1,.15)]),'stretch');ru.seat.burst({x:0,y:this.bearY(ru.seat)},white(1,.8),5,50)}
 began(seat){this.jump(this.runners[seat.index])}
 jumpHeight(ru){if(ru.airT<0)return 0;const p=ru.airT/AIR;return 4*46*p*(1-p)}
 gameUpdate(dt){for(const ru of this.runners){const s=ru.seat;
   if(s.isCPU&&!ru.finished&&ru.next<this.hd.length&&ru.airT<0){const remain=this.hd[ru.next]-ru.dist;if(ru.cpuJumped!==ru.next){const sp=Math.max(60,this.speed(ru));if(remain<=sp*(AIR/2+ru.cpuErr)){ru.cpuJumped=ru.next;if(!ru.cpuSkip)this.jump(ru)}}}
   if(ru.stumble>0)ru.stumble=Math.max(0,ru.stumble-dt);const v=this.speed(ru);ru.dist+=v*dt;
   if(ru.airT>=0){ru.airT+=dt;if(ru.airT>=AIR){ru.airT=-1;ru.bear.squash();s.burst({x:0,y:this.bearY(s)},white(1,.7),6,60)}}
   const hgt=this.jumpHeight(ru);ru.bear.x=0;ru.bear.y=this.bearY(s)+hgt;const sc=1-hgt/120;ru.shadow.setScale(Math.max(.5,sc));ru.shadow.alpha=Math.max(.4,sc);
   while(ru.next<this.hd.length&&ru.dist>=this.hd[ru.next]&&!ru.finished){const i=ru.next;ru.next++;const ok=this.jumpHeight(ru)>14,hy=this.bearY(s);
    if(ok){ru.cleared++;ru.combo++;ru.bonus=Math.min(100,ru.bonus+12);this.addScore(s,1);this.addStat('hits',1,s);s.floatText(ru.combo>1?'+1  x'+ru.combo:'+1',{x:0,y:hy+70},Theme.green,20);s.burst({x:0,y:hy},Theme.green,8,90);Sfx.play('coin');if(!s.isCPU)Haptic.tap('medium');ru.hurdles[i].run(A.sequence([A.scaleTo(1.15,.08),A.scaleTo(1,.12)]))}
    else{ru.combo=0;ru.bonus=0;ru.stumble=.9;ru.failed.add(i);s.shake(5);s.flash('#f00',.25,.3);s.floatText('AUTSCH',{x:0,y:hy+70},'#f00',20);s.burst({x:0,y:hy},Theme.pink,12,120);Sfx.play('hit');if(!s.isCPU)Haptic.bad();
     ru.bear.run(A.sequence([A.rotateBy(.35,.07),A.rotateBy(-.35,.15)]));const n=ru.hurdles[i];n.hidden=false;n.run(A.sequence([A.group([A.rotateBy(1.2,.4),A.moveBy(30,40,.4),A.fadeOut(.4)]),A.hide()]))}
    ru.comboLabel.text=ru.combo>=2?'SERIE '+ru.combo:'';
    if(ru.next<this.hd.length){const q=1-s.skill;ru.cpuErr=this.cpuRand.range(-1,1)*(.02+q*.26);ru.cpuSkip=this.cpuRand.chance(q*.18)}}
   if(ru.next===0&&ru.cpuErr===0&&s.isCPU){const q=1-s.skill;ru.cpuErr=this.cpuRand.range(-1,1)*(.02+q*.26)}
   this.layoutRunner(ru);if(!ru.finished&&ru.dist>=this.finishDist)this.finish(ru)}
  if(this.endTimer>=0){this.endTimer-=dt;if(this.endTimer<=0)this.finishGame()}}
 finish(ru){ru.finished=true;ru.place=this.finishedCount+1;this.finishedCount++;const bonus=ru.place===1?5:(ru.place===2?3:(ru.place===3?1:0)),s=ru.seat;this.addScore(s,bonus);ru.bear.stopRun();ru.bear.celebrate();ru.comboLabel.text='';
  s.banner('PLATZ '+ru.place,ru.place===1?'#ff0':s.color,34,1.4);if(bonus>0)s.floatText('+'+bonus,{x:0,y:this.bearY(s)+90},'#ff0',26);s.burst({x:0,y:this.bearY(s)+30},'#ff0',22,160);Sfx.play(ru.place===1?'fanfare':'whistle');if(!s.isCPU)Haptic.good();
  if(this.finishedCount>=this.seats.length)this.endTimer=1.2}
}
Arcade.register('hurdles',HurdlesGame);
})();
