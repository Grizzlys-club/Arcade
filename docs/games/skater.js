(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class SkaterGame extends MiniScene{
 setupGame(){this.duration=40;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),lw=Math.min(76,p.w/3.3),st={p,lw,lane:1,items:[],spawn:.5,stun:0,cpu:.3,scroll:0};
  for(let i=0;i<3;i++){const l=new Sprite(Gfx.rect(lw-6,p.h-6,white(1,.05),8),lw-6,p.h-6);l.x=(i-1)*lw;l.y=p.cy;l.z=-4;s.field.add(l)}
  const b=this.makeBear(s,44,true);b.x=0;b.y=p.cy-p.h/2+46;b.z=20;b.startRun(.1);s.field.add(b);st.bear=b;
  if(!s.isCPU){const h=label('◀ TIPPEN ▶ = SPUR WECHSELN',12,white(1,.7));h.y=p.cy+p.h/2-22;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}return st})}
 itemTex(k){return Gfx.texture('skat_'+k,40,40,2,c=>{if(k==='puck'){c.fillStyle='#111';c.beginPath();c.ellipse(20,24,16,8,0,0,7);c.fill();c.fillRect(4,16,32,8);c.fillStyle='#444';c.beginPath();c.ellipse(20,16,16,8,0,0,7);c.fill();c.strokeStyle='#ff6a00';c.lineWidth=2;c.stroke()}else{c.fillStyle='#ff5a1f';c.beginPath();c.moveTo(20,3);c.lineTo(35,36);c.lineTo(5,36);c.closePath();c.fill();c.fillStyle='#fff';c.fillRect(11,22,18,5)}})}
 gameUpdate(dt){const t=this.elapsed/this.duration,spd=150+t*130;for(const s of this.seats){const st=this.st[s.index],p=st.p,by=st.bear.y;st.spawn-=dt;st.stun-=dt;
  if(st.spawn<=0){st.spawn=NK.rr(.45,.8)*(1-t*.3);const ln=Math.floor(Math.random()*3),k=Math.random()<.5?'puck':'cone',n=new Sprite(this.itemTex(k),32,32);n.x=(ln-1)*st.lw;n.y=p.cy+p.h/2+20;n.z=10;s.field.add(n);st.items.push({n,k,ln})}
  for(const it of st.items){it.n.y-=spd*dt;if(!it.done&&Math.abs(it.n.y-by)<20&&it.ln===st.lane){it.done=true;it.n.run(A.sequence([A.group([A.scaleTo(1.7,.15),A.fadeOut(.15)]),A.remove()]));const pos={x:it.n.x,y:by+30};
    if(it.k==='puck'){this.addScore(s,1);this.addStat('hits',1,s);s.floatText('+1',pos,s.color,20);s.burst(pos,s.color,8,80);Sfx.play('pop')}else if(st.stun<=0){this.addScore(s,-2);st.stun=.6;s.floatText('−2',pos,'#f44',22);s.flash('#f00',.2);s.shake(4);Sfx.play('wrong');st.bear.alpha=.5;st.bear.run(A.sequence([A.wait(.5),A.fadeTo(1,.1)]))}}
   if(it.n.y<p.cy-p.h/2-30)it.dead=true}
  st.items=st.items.filter(i=>{if(i.dead)i.n.run(A.remove());return!i.dead});
  if(s.isCPU){st.cpu-=dt;if(st.cpu<=0){st.cpu=.12+(1-s.skill)*.3;const ahead=st.items.filter(i=>!i.done&&i.n.y>by&&i.n.y<by+170);const bad=l=>ahead.some(i=>i.ln===l&&i.k==='cone'),good=l=>ahead.some(i=>i.ln===l&&i.k==='puck');
   if(Math.random()<.4+s.skill*.6){let best=st.lane,sc=-9;for(let l=0;l<3;l++){let v=(good(l)?2:0)-(bad(l)?5:0)-Math.abs(l-st.lane)*.5;if(v>sc){sc=v;best=l}}this.go(s,best)}}}
  st.bear.x+=(((st.lane-1)*st.lw)-st.bear.x)*Math.min(1,dt*18)}}
 began(s,at){const st=this.st[s.index];this.go(s,at.x<0?Math.max(0,st.lane-1):Math.min(2,st.lane+1))}
 go(s,l){const st=this.st[s.index];if(l!==st.lane){st.lane=l;Sfx.play('tick')}}
}
Arcade.register('skater',SkaterGame);})();
