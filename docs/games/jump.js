(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class JumpGame extends MiniScene{
 setupGame(){this.duration=40;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),gy=p.cy-p.h/2+80,st={p,gy,phase:0,jumpT:-9,lives:3,streak:0,hearts:[],cpu:0,hit:false,T:1.5,cross:false};
  const fl=new Sprite(Gfx.pill(p.w-30,4,white(1,.4),null,2,false),p.w-30,4);fl.y=gy-4;fl.z=2;s.field.add(fl);
  const b=this.makeBear(s,54,true);b.x=0;b.y=gy;b.z=20;s.field.add(b);st.bear=b;
  const sh=new Sprite(Gfx.shadow(),50,18);sh.y=gy-6;sh.z=3;s.field.add(sh);st.sh=sh;
  st.rope=new Sprite(Gfx.pill(p.w-50,7,'#ffd61a',null,3,false),p.w-50,7);st.rope.z=25;s.field.add(st.rope);st.glow=NK.dot(s,'#ffd61a',60,24);st.glow.alpha=.0;
  for(let i=0;i<3;i++){const h=label('♥',16,s.color);h.x=p.w/2-18-i*18;h.y=p.cy+p.h/2-16;h.z=9;s.field.add(h);st.hearts.push(h)}
  if(!s.isCPU){const h=label('TIPPEN = SPRINGEN',12,white(1,.7));h.y=p.cy+p.h/2-44;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}return st})}
 gameUpdate(dt){const t=this.elapsed/this.duration;for(const s of this.seats){const st=this.st[s.index];if(st.lives<=0)continue;st.T=1.6-.8*t;const prev=st.phase;st.phase+=dt/st.T;
  const air=this.elapsed-st.jumpT,jh=air>=0&&air<.5?Math.sin(air/.5*Math.PI)*58:0;st.bear.y=st.gy+jh;st.sh.sx=1-jh/120;
  if(Math.floor(st.phase)>Math.floor(prev)){st.cross=false}
  const f=st.phase%1,ang=f*Math.PI*2,h=Math.cos(ang)*(st.p.h*.38);st.rope.y=st.gy+54+h;st.glow.x=0;st.glow.y=st.rope.y;st.rope.rot=Math.sin(ang)*.05;
  const near=Math.abs(st.rope.y-(st.gy+20));if(!st.cross&&st.rope.y<st.gy+30&&Math.cos(ang)<0){st.cross=true;if(jh>22){st.streak++;this.addScore(s,1+(st.streak>=5?1:0));s.floatText('+'+(1+(st.streak>=5?1:0)),{x:0,y:st.gy+90},s.color,20);Sfx.play('pop');NK.ring(s,{x:0,y:st.gy},s.color,14)}else{st.lives--;st.streak=0;Sfx.play('wrong');s.flash('#f00',.3);s.shake(6);s.floatText('AUA!',{x:0,y:st.gy+90},'#f44',22);if(st.hearts[st.lives])st.hearts[st.lives].alpha=.2;st.bear.run(A.sequence([A.rotateBy(.4,.08),A.rotateTo(0,.15)]));if(st.lives<=0){s.knockOut('RAUS');if(this.seats.every(o=>this.st[o.index].lives<=0))this.finishGame()}}}
  if(s.isCPU&&st.lives>0){const hh=st.p.h*.38,ac=Math.acos(Math.max(-1,Math.min(1,-24/hh))),lead=(.16+(1-s.skill)*.1*(Math.random()<.5?1:-1))/st.T*Math.PI*2;if(f<.02)st.cj=false;if(!st.cj&&ang>ac-lead&&ang<ac){st.cj=true;if(Math.random()<.5+s.skill*.48)st.jumpT=this.elapsed}}}}
 began(s){const st=this.st[s.index];if(st.lives<=0)return;if(this.elapsed-st.jumpT>.55){st.jumpT=this.elapsed;Sfx.play('jump');if(!s.isCPU)Haptic.tap('light')}}
}
Arcade.register('jump',JumpGame);})();
